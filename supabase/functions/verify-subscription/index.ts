// Supabase Edge Function for server-side subscription verification
// Prevents tampering and ensures secure validation of Google Play purchases
// Uses Google Play Developer API v3 with OAuth2 service account authentication

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GOOGLE_PLAY_PACKAGE_NAME = Deno.env.get('GOOGLE_PLAY_PACKAGE_NAME') || 'com.biohacker.biohacker_app'
const GOOGLE_SERVICE_ACCOUNT_EMAIL = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL') || ''
const GOOGLE_PRIVATE_KEY = Deno.env.get('GOOGLE_PRIVATE_KEY') || ''

interface VerificationRequest {
  user_id: string
  purchase_token: string
  product_id: string
  platform: 'android' | 'ios'
}

interface GooglePlaySubscriptionResponse {
  kind: string
  startTimeMillis: string
  expiryTimeMillis: string
  autoRenewing: boolean
  priceCurrencyCode: string
  priceAmountMicros: string
  countryCode: string
  developerPayload: string
  paymentState: number // 0 = pending, 1 = received, 2 = free trial, 3 = pending deferred upgrade/downgrade
  cancelReason?: number // 0 = user, 1 = system, 2 = replaced, 3 = developer
  orderId: string
  purchaseType?: number // 0 = test, 1 = promo, 2 = rewarded
  acknowledgementState: number // 0 = not acknowledged, 1 = acknowledged
}

serve(async (req) => {
  try {
    // CORS headers
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Verify user is authenticated
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const body: VerificationRequest = await req.json()

    // Validate request body
    if (!body.user_id || !body.purchase_token || !body.product_id || !body.platform) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Verify the requesting user matches the user_id in the request
    if (user.id !== body.user_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'User mismatch' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Check for duplicate purchase token (idempotency)
    const { data: existingPurchase } = await supabaseClient
      .from('subscription_purchases')
      .select('id, verified_at')
      .eq('purchase_token', body.purchase_token)
      .eq('user_id', body.user_id)
      .single()

    if (existingPurchase) {
      console.log(`Purchase token already verified: ${body.purchase_token}`)
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Purchase already verified',
          verified_at: existingPurchase.verified_at 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Verify the purchase with the appropriate platform
    let verificationResult: {
      isValid: boolean
      expiresAt: Date | null
      startedAt: Date | null
      isAutoRenewing: boolean
      paymentState: string
      error?: string
    }

    if (body.platform === 'android') {
      verificationResult = await verifyGooglePlayPurchase(
        body.purchase_token,
        body.product_id
      )
    } else if (body.platform === 'ios') {
      return new Response(
        JSON.stringify({ success: false, error: 'iOS verification not yet implemented' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid platform' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!verificationResult.isValid) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: verificationResult.error || 'Invalid purchase' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Record the verified purchase
    const { error: insertError } = await supabaseClient
      .from('subscription_purchases')
      .insert({
        user_id: body.user_id,
        product_id: body.product_id,
        purchase_token: body.purchase_token,
        platform: body.platform,
        verified_at: new Date().toISOString(),
        expires_at: verificationResult.expiresAt?.toISOString(),
        is_active: true,
      })

    if (insertError) {
      console.error('Failed to record purchase:', insertError)
      return new Response(
        JSON.stringify({ success: false, error: 'Database error' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Update user profile with subscription status
    const { error: updateError } = await supabaseClient
      .from('user_profiles')
      .update({
        subscription_tier: 'premium',
        subscription_starts_at: verificationResult.startedAt?.toISOString() || new Date().toISOString(),
        subscription_ends_at: verificationResult.expiresAt?.toISOString(),
      })
      .eq('id', body.user_id)

    if (updateError) {
      console.error('Failed to update user profile:', updateError)
      // Note: Purchase is recorded but profile update failed - manual intervention may be needed
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        expires_at: verificationResult.expiresAt,
        started_at: verificationResult.startedAt,
        is_auto_renewing: verificationResult.isAutoRenewing,
        payment_state: verificationResult.paymentState
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Verification error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Unknown error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Verify a Google Play subscription purchase
 * Uses Google Play Developer API v3 with OAuth2 service account
 */
async function verifyGooglePlayPurchase(
  purchaseToken: string,
  productId: string
): Promise<{
  isValid: boolean
  expiresAt: Date | null
  startedAt: Date | null
  isAutoRenewing: boolean
  paymentState: string
  error?: string
}> {
  try {
    // Get OAuth2 access token
    const accessToken = await getGoogleOAuth2Token()

    if (!accessToken) {
      return {
        isValid: false,
        expiresAt: null,
        startedAt: null,
        isAutoRenewing: false,
        paymentState: 'error',
        error: 'Failed to obtain OAuth2 token'
      }
    }

    // Call Google Play Developer API to verify the subscription
    // API docs: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get
    const apiUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${GOOGLE_PLAY_PACKAGE_NAME}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`

    const response = await fetch(apiUrl, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Google Play API error:', response.status, errorText)
      
      if (response.status === 404) {
        return {
          isValid: false,
          expiresAt: null,
          startedAt: null,
          isAutoRenewing: false,
          paymentState: 'not_found',
          error: 'Purchase not found'
        }
      }

      return {
        isValid: false,
        expiresAt: null,
        startedAt: null,
        isAutoRenewing: false,
        paymentState: 'error',
        error: `API error: ${response.status}`
      }
    }

    const data: GooglePlaySubscriptionResponse = await response.json()

    // Check payment state
    // 0 = Payment pending, 1 = Payment received, 2 = Free trial, 3 = Pending deferred upgrade/downgrade
    const isPaymentValid = [1, 2, 3].includes(data.paymentState)
    
    // Check acknowledgement state (subscriptions must be acknowledged within 3 days)
    const isAcknowledged = data.acknowledgementState === 1

    // Parse timestamps
    const expiresAt = data.expiryTimeMillis 
      ? new Date(parseInt(data.expiryTimeMillis))
      : null

    const startedAt = data.startTimeMillis
      ? new Date(parseInt(data.startTimeMillis))
      : null

    // Check if expired
    const isExpired = expiresAt ? expiresAt < new Date() : false

    // Determine payment state label
    let paymentStateLabel = 'unknown'
    switch (data.paymentState) {
      case 0: paymentStateLabel = 'pending'; break
      case 1: paymentStateLabel = 'received'; break
      case 2: paymentStateLabel = 'trial'; break
      case 3: paymentStateLabel = 'deferred'; break
    }

    // Purchase is valid if:
    // - Payment is in valid state
    // - Not expired
    // - (Acknowledgement is handled separately but we check it here for logging)
    const isValid = isPaymentValid && !isExpired

    if (!isAcknowledged) {
      console.warn(`Purchase not acknowledged: ${purchaseToken}`)
    }

    return {
      isValid,
      expiresAt,
      startedAt,
      isAutoRenewing: data.autoRenewing,
      paymentState: paymentStateLabel,
      error: isValid ? undefined : (isExpired ? 'Subscription expired' : 'Invalid payment state')
    }

  } catch (error) {
    console.error('Google Play verification error:', error)
    return {
      isValid: false,
      expiresAt: null,
      startedAt: null,
      isAutoRenewing: false,
      paymentState: 'error',
      error: error.message || 'Unknown verification error'
    }
  }
}

/**
 * Get OAuth2 access token using service account
 * Uses JWT assertion for authentication
 */
async function getGoogleOAuth2Token(): Promise<string | null> {
  try {
    if (!GOOGLE_SERVICE_ACCOUNT_EMAIL || !GOOGLE_PRIVATE_KEY) {
      console.error('Google service account credentials not configured')
      return null
    }

    // Create JWT header and payload
    const now = Math.floor(Date.now() / 1000)
    const exp = now + 3600 // Token valid for 1 hour

    const header = {
      alg: 'RS256',
      typ: 'JWT'
    }

    const payload = {
      iss: GOOGLE_SERVICE_ACCOUNT_EMAIL,
      scope: 'https://www.googleapis.com/auth/androidpublisher',
      aud: 'https://oauth2.googleapis.com/token',
      exp,
      iat: now
    }

    // Base64url encode header and payload
    const base64urlEncode = (obj: any) => {
      return btoa(JSON.stringify(obj))
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '')
    }

    const encodedHeader = base64urlEncode(header)
    const encodedPayload = base64urlEncode(payload)
    const signatureInput = `${encodedHeader}.${encodedPayload}`

    // Sign with private key
    // Note: Deno has built-in crypto support for signing
    const privateKeyPem = GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n')
    
    // Import the private key
    const privateKey = await crypto.subtle.importKey(
      'pkcs8',
      pemToArrayBuffer(privateKeyPem),
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256'
      },
      false,
      ['sign']
    )

    // Sign the JWT
    const signatureBuffer = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      privateKey,
      new TextEncoder().encode(signatureInput)
    )

    // Base64url encode signature
    const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')

    const jwt = `${signatureInput}.${signature}`

    // Exchange JWT for access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      })
    })

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error('OAuth2 token request failed:', tokenResponse.status, errorText)
      return null
    }

    const tokenData = await tokenResponse.json()
    return tokenData.access_token

  } catch (error) {
    console.error('OAuth2 token error:', error)
    return null
  }
}

/**
 * Convert PEM format private key to ArrayBuffer
 */
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  
  const binaryString = atob(base64)
  const bytes = new Uint8Array(binaryString.length)
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  
  return bytes.buffer
}
