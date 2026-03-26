# Google Play Data Safety Form

**DRAFT - REVIEW REQUIRED**

This document maps to Google Play's Data Safety section requirements.

---

## Data Collection and Security

### Does your app collect or share user data?
**YES**

---

## Data Types Collected

### 1. Health and Fitness
**Collected:** YES  
**Shared:** NO  
**Optional:** NO (core functionality)  
**Specific Data:**
- Laboratory test results (blood work, biomarkers, metabolic panels)
- Peptide protocols and dosing schedules
- Cycle tracking information (start/end dates, protocol details)
- Health metrics and biomarker trends
- Research notes and personal health observations

**Purpose:**
- App functionality (health tracking, protocol management)
- Analytics (anonymized, aggregated trends only—no PHI)
- Personalization (AI insights based on your data)

**User Control:**
- Can request deletion via in-app settings
- Can export data in JSON/CSV/PDF formats
- Can modify or correct data anytime

---

### 2. Personal Info
**Collected:** YES  
**Shared:** NO  
**Optional:** NO (required for account creation)  
**Specific Data:**
- Name
- Email address

**Purpose:**
- App functionality (account creation, authentication)
- Account management

**User Control:**
- Can update via profile settings
- Can delete account entirely

---

### 3. App Activity
**Collected:** YES (if analytics enabled)  
**Shared:** NO  
**Optional:** YES (user can opt out)  
**Specific Data:**
- App feature usage (which screens visited, buttons tapped)
- Session duration and frequency
- Error logs and crash reports (de-identified)

**Purpose:**
- Analytics (improve app performance and UX)
- Diagnostics (identify and fix bugs)

**User Control:**
- Toggle analytics on/off in settings
- No PHI included in analytics data

---

### 4. Device or Other IDs
**Collected:** YES  
**Shared:** NO  
**Optional:** NO  
**Specific Data:**
- Device identifiers (for biometric authentication)
- Operating system version
- App version

**Purpose:**
- App functionality (biometric login, compatibility checks)
- Fraud prevention, security, and compliance

**User Control:**
- Required for biometric authentication (can disable biometrics if preferred)

---

## Data Sharing

### Do you share user data with third parties?
**NO** — We do not sell or share your personal or health data with third parties for marketing purposes.

### Third-Party Service Providers (Business Associates)
We use HIPAA-compliant service providers to operate the app. These are **not** considered "sharing" under HIPAA because they process data on our behalf under Business Associate Agreements:

**Supabase (Database & Authentication):**
- Stores encrypted health data
- HIPAA-compliant infrastructure
- Signed Business Associate Agreement (BAA)

**Google Cloud Platform (Backend Services):**
- Hosts AI analysis services
- HIPAA-compliant infrastructure
- Signed Business Associate Agreement (BAA)

**Analytics Providers (Optional):**
- De-identified usage data only
- **No PHI shared**
- User can opt out

---

## Data Security Practices

### Encryption in Transit
**YES** — All data transmitted between your device and our servers is encrypted using **TLS 1.3** (Transport Layer Security).

### Encryption at Rest
**YES** — All health data stored in our database is encrypted using **AES-256 encryption** (military-grade).

### User Authentication
**YES** — Secure password hashing (bcrypt) + optional biometric authentication (fingerprint/Face ID).

### Session Security
**YES** — Automatic session timeout after **15 minutes** of inactivity.

### Access Controls
**YES** — Row-level security enforced in database; users can only access their own data.

### Audit Logging
**YES** — All access to Protected Health Information (PHI) is logged and monitored.

---

## Data Retention and Deletion

### How long is data retained?
- **Active accounts:** Data retained indefinitely while account is active
- **Inactive accounts:** Accounts inactive for 3+ years will receive deletion notice
- **User-initiated deletion:** Data permanently deleted within **30 days** of request
- **Backups:** Backup copies purged within **90 days** of deletion request

### Can users request data deletion?
**YES**

**How:**
- Use "Delete Account" feature in app settings
- Email privacy@biohacker.systems

**Confirmation:**
- Deletion is permanent and irreversible
- User receives confirmation email when complete

---

## HIPAA Compliance

### Is your app HIPAA compliant?
**YES**

**Details:**
- Compliant with HIPAA Privacy Rule and Security Rule
- Business Associate Agreements (BAAs) with all third-party processors
- Administrative, physical, and technical safeguards implemented
- Breach notification procedures in place
- Users receive Notice of Privacy Practices upon account creation

**Documentation:**
- Privacy Policy (accessible in-app and at privacy@biohacker.systems)
- HIPAA Notice of Privacy Practices (accessible in-app)
- Terms of Service (accessible in-app)

---

## User Rights

Users have the right to:
- **Access:** View all health data in-app; export complete data history
- **Modify:** Edit or update any information anytime
- **Delete:** Request complete account and data deletion (permanent within 30 days)
- **Export:** Download data in JSON, CSV, or PDF format
- **Restrict:** Opt out of optional analytics
- **Complaint:** File privacy complaints with us or HHS Office for Civil Rights

---

## Contact Information

**Privacy Questions:** privacy@biohacker.systems  
**Data Deletion Requests:** privacy@biohacker.systems  
**Security Concerns:** security@biohacker.systems  
**General Support:** support@biohacker.systems

---

## Independent Security Review

**Status:** [Pending]  
**Planned:** Third-party security audit and penetration testing before public launch  
**Certification Target:** SOC 2 Type II (future consideration)

---

**Document Control:**  
Version: 1.0 DRAFT  
Review Required: Legal, Compliance, Privacy Officer  
Google Play Submission Checklist: Data Safety section completed  
