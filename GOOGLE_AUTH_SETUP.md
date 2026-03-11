# Google OAuth Setup for Biohacker App

This guide walks you through setting up Google OAuth authentication with Supabase for the Biohacker Flutter app.

## Prerequisites

- A Google Cloud Platform account
- Access to your Supabase project dashboard
- The Biohacker Flutter app repository

## Part 1: Google Cloud Console Setup

### 1. Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services > Credentials**
4. Click **Create Credentials > OAuth client ID**
5. If prompted, configure the OAuth consent screen:
   - Select **External** user type
   - Fill in required fields (App name, User support email, Developer contact)
   - Add scopes: `email`, `profile`, `openid`
   - Save and continue

### 2. Configure OAuth Client ID

Choose the platform(s) you're building for:

#### For Android:
1. Select **Android** as the application type
2. Enter the package name: `com.example.biohacker_app` (or your actual package name)
3. Get your SHA-1 certificate fingerprint:
   ```bash
   # For debug builds
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # For release builds
   keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
   ```
4. Copy the SHA-1 fingerprint and paste it
5. Click **Create**

#### For iOS:
1. Select **iOS** as the application type
2. Enter the bundle identifier: `com.example.biohackerApp` (or your actual bundle ID)
3. Click **Create**

#### For Web:
1. Select **Web application** as the application type
2. Add authorized JavaScript origins:
   - `http://localhost:3000` (for local testing)
   - Your Supabase project URL
3. Add authorized redirect URIs (you'll get this from Supabase in Part 2)
4. Click **Create**

### 3. Save Your Credentials

- Copy the **Client ID** (you'll need this for Supabase)
- Copy the **Client Secret** (for web apps)
- Keep these credentials secure

## Part 2: Supabase Configuration

### 1. Enable Google Provider

1. Log in to your [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Authentication > Providers**
4. Find **Google** in the provider list
5. Toggle **Enable Sign in with Google** to ON

### 2. Configure Google OAuth Settings

1. Paste your **Google Client ID** from Part 1
2. Paste your **Google Client Secret** (for web apps)
3. Copy the **Callback URL** shown in Supabase (it looks like):
   ```
   https://your-project-ref.supabase.co/auth/v1/callback
   ```
4. Click **Save**

### 3. Update Google Cloud Console with Callback URL

1. Return to [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services > Credentials**
3. Click on your OAuth 2.0 Client ID
4. Add the Supabase callback URL to **Authorized redirect URIs**:
   ```
   https://your-project-ref.supabase.co/auth/v1/callback
   ```
5. Click **Save**

### 4. Configure Additional Settings (Optional)

In Supabase Authentication settings, you can configure:

- **Auto-confirm users**: ON (users won't need email verification)
- **Email templates**: Customize the welcome email for Google sign-ups
- **Redirect URLs**: Add your app's deep link scheme for mobile redirects
  - Example: `com.example.biohacker://login-callback`

## Part 3: Mobile App Configuration

### Android Setup

1. Add the following to `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           // Add your SHA-1 fingerprint
           manifestPlaceholders = [
               'appAuthRedirectScheme': 'com.example.biohacker_app'
           ]
       }
   }
   ```

2. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <activity
       android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
       android:exported="true">
       <intent-filter android:label="flutter_web_auth_2">
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="com.example.biohacker_app" />
       </intent-filter>
   </activity>
   ```

### iOS Setup

1. Add the following to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.example.biohackerapp</string>
           </array>
       </dict>
   </array>
   ```

2. Add your Google Client ID (reversed) to the URL schemes in Info.plist

## Part 4: Testing

### Test Google Sign-In Flow

1. Run your Flutter app:
   ```bash
   flutter run
   ```

2. Navigate to the login screen
3. Tap the **Continue with Google** button
4. You should see the Google account picker
5. Select an account
6. Grant permissions
7. You should be redirected back to the app and logged in

### Troubleshooting

#### "Error 400: redirect_uri_mismatch"
- Verify the redirect URI in Google Cloud Console matches the Supabase callback URL exactly
- Check for typos or extra spaces

#### "Sign in failed" or timeout
- Ensure your Google OAuth credentials are correct in Supabase
- Check that the OAuth client is enabled in Google Cloud Console
- Verify network connectivity

#### App crashes on Android
- Verify SHA-1 fingerprint is correct
- Check that the package name matches
- Ensure AndroidManifest.xml is configured correctly

#### iOS not showing Google sign-in
- Verify bundle ID matches
- Check Info.plist configuration
- Ensure URL scheme is correctly set

#### User not appearing in Supabase
- Check Authentication > Users in Supabase dashboard
- Verify auto-confirm is enabled
- Check Supabase logs for errors

### Verify in Supabase Dashboard

1. Go to **Authentication > Users**
2. After successful sign-in, you should see the new user
3. The user's provider should show as "google"
4. User metadata will include Google profile info (name, picture)

## Security Best Practices

1. **Keep credentials secure**: Never commit client secrets to version control
2. **Use environment variables**: Store sensitive config in `.env` files (add to `.gitignore`)
3. **Limit OAuth scopes**: Only request email, profile, and openid
4. **Enable MFA**: Consider enabling multi-factor authentication in Supabase
5. **Monitor usage**: Check Supabase logs for suspicious authentication attempts
6. **Rotate credentials**: Periodically update OAuth credentials
7. **Use different credentials for dev/prod**: Keep separate OAuth clients for development and production

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Supabase Google OAuth Guide](https://supabase.com/docs/guides/auth/social-login/auth-google)

## Support

If you encounter issues:
1. Check Supabase logs: **Authentication > Logs**
2. Check Flutter console for error messages
3. Verify all configuration steps were completed
4. Test with multiple Google accounts
5. Try clearing app data and reinstalling
