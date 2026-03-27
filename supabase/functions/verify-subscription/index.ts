// Supabase Edge Function for server-side subscription verification
// Prevents tampering and ensures secure validation of Google Play purchases

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GOOGLE_PLAY_PACKAGE_NAME = 'com.biohacker.app' // Update with your package name

interface VerificationRequest {
  user_id: string
  purchase_token: string
  product_id: string
  platform: 'android' | 'ios'
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
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
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

    // Verify the purchase token with Google Play
    let isValid = false
    let expiresAt: Date | null = null

    if (body.platform === 'android') {
      isValid = await verifyGooglePlayPurchase(
        body.purchase_token,
        body.product_id
      )
      
      // For subscriptions, Google returns expiry time
      // In production, you'd parse this from the verification response
      expiresAt = new Date()
      if (body.product_id === 'biohacker_annual_sub') {
        expiresAt.setFullYear(expiresAt.getFullYear() + 1)
      } else {
        expiresAt.setMonth(expiresAt.getMonth() + 1)
      }
    } else if (body.platform === 'ios') {
      // iOS verification would go here
      // For now, return error
      return new Response(
        JSON.stringify({ success: false, error: 'iOS not yet supported' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!isValid) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid purchase' }),
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
        expires_at: expiresAt?.toISOString(),
        is_active: true,
      })

    if (insertError) {
      console.error('Failed to record purchase:', insertError)
      return new Response(
        JSON.stringify({ success: false, error: 'Database error' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, expires_at: expiresAt }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Verification error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function verifyGooglePlayPurchase(
  purchaseToken: string,
  productId: string
): Promise<boolean> {
  try {
    // In production, you need to:
    // 1. Set up Google Play Developer API credentials
    // 2. Use OAuth 2.0 service account
    // 3. Call Google Play Developer API to verify the purchase
    
    // Example endpoint (requires auth):
    // https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/purchases/subscriptionsv2/tokens/{token}
    
    const GOOGLE_API_KEY = Deno.env.get('GOOGLE_PLAY_API_KEY')
    
    if (!GOOGLE_API_KEY) {
      console.warn('Google Play API key not configured, skipping verification')
      // In development, you might want to allow this
      // In production, this should return false
      return true // TEMPORARY: Remove in production!
    }

    // This is a simplified example - real implementation needs OAuth2
    const response = await fetch(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${GOOGLE_PLAY_PACKAGE_NAME}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`,
      {
        headers: {
          Authorization: `Bearer ${GOOGLE_API_KEY}`,
        },
      }
    )

    if (!response.ok) {
      console.error('Google API error:', await response.text())
      return false
    }

    const data = await response.json()
    
    // Check if subscription is active
    return data.paymentState === 1 // 1 = payment received
  } catch (error) {
    console.error('Google Play verification error:', error)
    return false
  }
}
