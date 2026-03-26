# Launch Checklist - Legal & Play Store Requirements

**Status:** DRAFT - Legal review required before launch  
**Last Updated:** March 26, 2026

---

## ✅ Completed

### Legal Documents (`legal/`)
- [x] **privacy_policy.md** - Comprehensive HIPAA-compliant privacy policy
  - Data collection/use/protection
  - User rights (access, modify, delete, export)
  - Third-party service providers (Supabase, GCP)
  - HIPAA compliance statement
  - Contact: privacy@biohacker.systems

- [x] **terms_of_service.md** - Complete terms covering all key areas
  - Medical disclaimer (not medical advice)
  - User obligations (18+, accurate info, secure credentials)
  - Liability limitations
  - Dispute resolution and governing law
  - Contact: legal@biohacker.systems

- [x] **hipaa_notice.md** - Expanded Notice of Privacy Practices
  - PHI handling and uses/disclosures
  - Security safeguards (encryption, access controls)
  - User rights under HIPAA
  - Breach notification procedures
  - Complaint procedures

### Play Store Assets (`store/`)
- [x] **store_listing.md** - Complete app description and metadata
  - Short description (75 chars)
  - Full description (~2,750 chars)
  - Key features list
  - Screenshot captions

- [x] **data_safety.md** - Google Play Data Safety form responses
  - Data types collected (health, personal, device)
  - Data sharing policy (none for marketing)
  - Security practices (AES-256, TLS 1.3, biometric)
  - HIPAA compliance disclosure
  - Retention and deletion policy

- [x] **screenshot_guide.md** - Detailed screenshot capture requirements
  - 7-8 required screens
  - Technical specs (1080x1920, PNG)
  - Demo data requirements
  - Annotation guidelines

### Security Documentation
- [x] **SECURITY.md** - Comprehensive security practices document
  - Encryption standards (AES-256, TLS 1.3)
  - Authentication (bcrypt, biometric, session timeout)
  - Access controls (RLS, RBAC)
  - Incident response plan
  - Vulnerability reporting: security@biohacker.systems

---

## 📋 Next Steps (Before Launch)

### 1. Legal Review (CRITICAL)
- [ ] **Engage legal counsel** to review all documents
- [ ] **Privacy Officer** review and sign-off
- [ ] **Compliance Officer** review for HIPAA accuracy
- [ ] Update placeholder company details:
  - [ ] Final entity name (currently "Biohacker Systems")
  - [ ] Physical mailing address
  - [ ] Privacy Officer name
  - [ ] Security Officer name
  - [ ] Governing law jurisdiction/state
  - [ ] Arbitration location

### 2. Business Setup
- [ ] Register email domain: **biohacker.systems**
- [ ] Set up email accounts:
  - [ ] privacy@biohacker.systems
  - [ ] legal@biohacker.systems
  - [ ] security@biohacker.systems
  - [ ] support@biohacker.systems
- [ ] Configure email forwarding/monitoring
- [ ] Designate Privacy Officer and Security Officer

### 3. HIPAA Compliance Verification
- [ ] **Business Associate Agreements (BAAs):**
  - [ ] Supabase - request and sign BAA
  - [ ] Google Cloud Platform - request and sign BAA
  - [ ] Any analytics provider - request and sign BAA
- [ ] **Risk Assessment:** Conduct initial HIPAA risk assessment
- [ ] **Workforce Training:** Complete HIPAA training (Privacy Officer, Security Officer, developers)
- [ ] **Policies & Procedures:** Document internal HIPAA policies

### 4. Play Store Preparation
- [ ] **Capture Screenshots** (follow `store/screenshot_guide.md`)
  - [ ] Screenshot 1: Login/Onboarding
  - [ ] Screenshot 2: Cycles Dashboard
  - [ ] Screenshot 3: Lab Results
  - [ ] Screenshot 4: Protocol Management
  - [ ] Screenshot 5: Biomarker Trends Chart
  - [ ] Screenshot 6: Research Library
  - [ ] Screenshot 7: Profile/Settings
  - [ ] Screenshot 8 (Optional): AI Insights Detail
- [ ] **Feature Graphic** (1024x500 pixels)
- [ ] **App Icon** (512x512 pixels, round and square variants)
- [ ] **Promo Video** (optional, 30-120 seconds)
- [ ] **Content Rating Questionnaire** (ESRB/PEGI)
- [ ] **Fill Data Safety Form** in Play Console (use `store/data_safety.md` as reference)

### 5. In-App Legal Display
- [ ] **Add legal documents to app:**
  - [ ] Privacy Policy accessible from login/signup screen
  - [ ] Terms of Service accessible from login/signup screen
  - [ ] HIPAA Notice accessible from profile/settings
  - [ ] All documents accessible in-app (not web-only)
- [ ] **User Acceptance:**
  - [ ] Require Privacy Policy acceptance during signup
  - [ ] Require Terms of Service acceptance during signup
  - [ ] Display HIPAA Notice upon first login
  - [ ] Log user acceptance with timestamp
- [ ] **Footer Links:**
  - [ ] Privacy Policy
  - [ ] Terms of Service
  - [ ] HIPAA Notice
  - [ ] Contact Us (support@biohacker.systems)

### 6. Security Implementation Verification
- [ ] **Encryption:**
  - [ ] Verify AES-256 at rest (Supabase)
  - [ ] Verify TLS 1.3 in transit (API calls)
  - [ ] Test session timeout (15 minutes)
- [ ] **Authentication:**
  - [ ] Test biometric login (fingerprint/Face ID)
  - [ ] Test password complexity requirements
  - [ ] Test session revocation
- [ ] **Access Controls:**
  - [ ] Test RLS (users can only see own data)
  - [ ] Test data export (JSON, CSV, PDF)
  - [ ] Test account deletion (data fully removed)
- [ ] **Audit Logging:**
  - [ ] Verify PHI access is logged
  - [ ] Test log retention (7-year requirement)

### 7. Incident Response Preparation
- [ ] **Document Incident Response Team:**
  - [ ] Privacy Officer (primary contact)
  - [ ] Security Officer (technical lead)
  - [ ] Legal Counsel (notification/compliance)
  - [ ] Executive Sponsor (decision-making authority)
- [ ] **Test Breach Notification Process:**
  - [ ] Draft breach notification email template
  - [ ] Test email delivery system
  - [ ] Identify HHS reporting portal credentials
- [ ] **Communication Plan:**
  - [ ] Draft press release template (if 500+ affected)
  - [ ] Identify media contacts
  - [ ] Social media response plan

### 8. Pre-Launch Testing
- [ ] **Legal Compliance Testing:**
  - [ ] Privacy Policy displayed correctly
  - [ ] Terms accepted before account creation
  - [ ] Data export functions work
  - [ ] Account deletion is permanent
- [ ] **Security Testing:**
  - [ ] Penetration test (third-party recommended)
  - [ ] Vulnerability scan
  - [ ] Code review for security issues
- [ ] **HIPAA Audit:**
  - [ ] Internal audit or third-party HIPAA audit
  - [ ] Document findings and remediation

---

## 🎯 Launch Day Checklist

- [ ] All legal documents live and accessible in-app
- [ ] Privacy Officer and Security Officer designated and available
- [ ] Incident response plan tested and ready
- [ ] Play Store listing submitted and approved
- [ ] BAAs signed with all third-party vendors
- [ ] Monitoring and alerting enabled (security, uptime)
- [ ] Support email monitored (support@biohacker.systems)
- [ ] Press release ready (if applicable)

---

## 📧 Contact Matrix

| Role | Name | Email | Responsibility |
|------|------|-------|---------------|
| Privacy Officer | [TBD] | privacy@biohacker.systems | HIPAA compliance, user data requests |
| Security Officer | [TBD] | security@biohacker.systems | Security incidents, vulnerability reports |
| Legal Counsel | [TBD] | legal@biohacker.systems | Legal questions, Terms updates |
| Support | [TBD] | support@biohacker.systems | User questions, troubleshooting |

---

## 📚 References

- **HIPAA Privacy Rule:** https://www.hhs.gov/hipaa/for-professionals/privacy/index.html
- **HIPAA Security Rule:** https://www.hhs.gov/hipaa/for-professionals/security/index.html
- **HIPAA Breach Notification:** https://www.hhs.gov/hipaa/for-professionals/breach-notification/index.html
- **Google Play Data Safety:** https://support.google.com/googleplay/android-developer/answer/10787469
- **Play Console Guidelines:** https://play.google.com/console/about/guides/

---

**Document Control:**  
Version: 1.0 DRAFT  
Owner: [Product Owner Name]  
Last Review: 2026-03-26  
Next Review: [Before launch]  
