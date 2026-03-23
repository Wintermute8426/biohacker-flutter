# Biohacker App - Production Deployment Plan

**Target:** Play Store launch with HIPAA-compliant infrastructure

---

## Phase 1: Infrastructure (REQUIRED BEFORE LAUNCH)

### 1.1 Lab PDF Endpoint - Production Deployment

**Current state:**
- Flask dev server on http://100.71.64.116:9000
- No HTTPS
- No authentication
- Local network only (Tailscale)

**Production requirements:**
- [ ] Deploy with gunicorn/uwsgi (production WSGI)
- [ ] HTTPS via nginx + Let's Encrypt OR Cloudflare Tunnel
- [ ] API key authentication (Bearer token)
- [ ] Rate limiting (prevent abuse)
- [ ] Publicly accessible endpoint OR VPN-only with docs
- [ ] Logging and monitoring
- [ ] Auto-restart on failure (systemd)

**Options:**
1. **Cloudflare Tunnel** (easiest, free HTTPS)
   - Run `cloudflared tunnel` to expose dashboard
   - Gets https://your-subdomain.trycloudflare.com
   - No port forwarding needed
   
2. **Nginx + Let's Encrypt** (traditional)
   - Need domain name
   - Configure nginx reverse proxy
   - Certbot for SSL certificates
   
3. **VPN-Only** (if keeping private)
   - Document Tailscale requirement
   - Only works for your use case
   - Not scalable for public app

**Recommendation:** Cloudflare Tunnel for MVP, migrate to full hosting later

---

### 1.2 BloodworkAI Service

**Current state:**
- Stub implementation
- No API key
- Non-functional

**Options:**
1. **Get real API key** - if service exists and is needed
2. **Disable feature** - remove from UI until ready
3. **Build alternative** - use Claude API for PDF extraction instead

**Recommendation:** Disable for MVP launch, enable post-launch

---

## Phase 2: HIPAA Compliance (REQUIRED FOR HEALTH DATA)

### 2.1 Supabase HIPAA Configuration

- [ ] Upgrade to Pro plan ($25/mo minimum for HIPAA)
- [ ] Sign Business Associate Agreement (BAA)
- [ ] Enable audit logging
- [ ] Configure automatic backups
- [ ] Document data retention policies
- [ ] Enable connection pooling (PgBouncer)

### 2.2 Application Security

- [ ] Complete security audit fixes ✅ (DONE)
- [ ] Implement session timeout (30 min inactivity)
- [ ] Add biometric authentication option
- [ ] Implement data encryption at rest verification
- [ ] Add audit trail for data access
- [ ] Privacy policy implementation
- [ ] Terms of service
- [ ] HIPAA notice in app

### 2.3 Infrastructure Security

- [ ] Production dashboard authentication
- [ ] API rate limiting
- [ ] DDoS protection (Cloudflare)
- [ ] Database connection encryption
- [ ] Regular security updates automation

---

## Phase 3: Play Store Requirements

### 3.1 App Compliance

- [ ] Privacy policy URL (required)
- [ ] Data safety form completion
- [ ] Target API level 34+ (Android 14)
- [ ] App signing key setup
- [ ] Store listing content
- [ ] Screenshots (6+ required)
- [ ] Feature graphic (1024x500)
- [ ] App icon (512x512)

### 3.2 Legal Requirements

- [ ] Privacy Policy (HIPAA-compliant)
- [ ] Terms of Service
- [ ] Data retention policy
- [ ] User rights (access, deletion, export)
- [ ] Age verification (13+ minimum)
- [ ] Medical disclaimer (not medical advice)

### 3.3 Technical Requirements

- [ ] Remove debug flags
- [ ] Disable dev tools in release
- [ ] Obfuscate code (ProGuard)
- [ ] Sign APK with production key
- [ ] Test on multiple devices
- [ ] Verify all features work without dev .env

---

## Phase 4: Final Testing

### 4.1 End-to-End Testing

- [ ] Fresh install test
- [ ] Onboarding flow
- [ ] Cycle creation and management
- [ ] Lab upload (all methods)
- [ ] Notifications (all 6 types)
- [ ] Protocol creation/initiation
- [ ] Data persistence across app restarts
- [ ] Logout/login flow
- [ ] Password reset

### 4.2 Security Testing

- [ ] Penetration testing (basic)
- [ ] Data isolation verification (RLS)
- [ ] Session management
- [ ] API endpoint security
- [ ] Input validation
- [ ] Error message sanitization

### 4.3 Performance Testing

- [ ] App startup time (<3s)
- [ ] Database query performance
- [ ] Image upload performance
- [ ] Notification delivery
- [ ] Offline functionality
- [ ] Memory usage

---

## Estimated Timeline

**Week 1:**
- Day 1-2: Production dashboard deployment (Cloudflare Tunnel)
- Day 3-4: Supabase HIPAA upgrade + BAA
- Day 5-7: App security hardening

**Week 2:**
- Day 1-3: Legal documentation (privacy policy, terms)
- Day 4-5: Play Store listing preparation
- Day 6-7: End-to-end testing

**Week 3:**
- Day 1-3: Security testing
- Day 4-5: Final fixes
- Day 6-7: Play Store submission

---

## Next Steps (Immediate)

1. **Choose deployment method** for lab PDF endpoint
2. **Set up Cloudflare Tunnel** (recommended)
3. **Add authentication** to dashboard API
4. **Upgrade Supabase** to Pro + sign BAA
5. **Create legal documents** (privacy policy, terms)
6. **Prepare Play Store listing**

---

## Cost Estimate

**Monthly recurring:**
- Supabase Pro (HIPAA): $25
- Cloudflare: $0 (free tier sufficient for MVP)
- Domain (if needed): $12/year = $1/mo
- **Total: ~$26/month**

**One-time:**
- Google Play Developer account: $25
- Legal document templates: $0 (use generators)
- **Total: ~$25**

---

## Decision Points

1. **Lab PDF endpoint:** Cloudflare Tunnel vs. full hosting?
2. **BloodworkAI:** Disable for MVP vs. get API key?
3. **Staging environment:** Create separate Supabase project?
4. **Beta testing:** Closed beta before public launch?

Ready to proceed with Phase 1?
