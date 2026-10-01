# 05 — Active Directory Account Lockout Detection

## Project goal

The goal of this project is to detect **Active Directory account lockouts** with Wazuh and automatically notify the administrator through **n8n + SMTP**.

This stage focuses only on **detection and notification**.

> Wazuh does not block the account in this project.  
> The account is locked by the Active Directory domain policy after too many failed authentication attempts.

---

## Scenario

1. A domain user enters an incorrect password several times.
2. Active Directory reaches the configured account lockout threshold.
3. The user account is locked by AD.
4. The Domain Controller generates Windows Security Event ID **4740**.
5. Wazuh collects the event from the Domain Controller.
6. A custom Wazuh rule identifies the account lockout.
7. Wazuh sends the alert to an n8n webhook.
8. n8n parses the alert and creates a readable notification.
9. The administrator receives an e-mail with the most important event details.

---

## Event monitored

### Windows Security Event ID 4740

**A user account was locked out**

Important fields to extract:

- Locked account name
- Domain
- Domain Controller
- Caller Computer Name
- Event ID
- Event time
- Wazuh Rule ID
- Wazuh Rule Level
- Agent name

The most useful field for troubleshooting is usually:

`Caller Computer Name`

It may help identify the workstation or server from which the failed authentication attempts originated.

---

## Planned architecture

```text
User / Workstation
       |
       | failed authentication attempts
       v
Active Directory Domain Controller
       |
       | Event ID 4740
       v
Wazuh Agent
       |
       v
Wazuh Manager
       |
       | Custom Rule
       v
n8n Webhook
       |
       | Parse / format alert
       v
SMTP
       |
       v
Administrator e-mail
```

---

## Project assumptions

### Wazuh

The Wazuh Agent installed on the Domain Controller must collect the Windows Security log.

The project will use:

- Windows Event ID `4740`
- custom Wazuh rule
- dedicated Rule ID from the local rules range
- alert forwarding to n8n

The custom rule should trigger only when an actual AD account lockout is recorded.

---

### Active Directory

A domain Account Lockout Policy must be configured.

Example LAB policy:

```text
Account lockout threshold: 5 invalid logon attempts
Account lockout duration: 5 minutes
Reset account lockout counter after: 5 minutes
```

These values are intended for a controlled laboratory environment.

Production settings should follow the organization's security policy and operational requirements.

---

### n8n

n8n will receive the Wazuh alert through a webhook.

The workflow should:

1. Receive the Wazuh JSON alert.
2. Extract the relevant Windows Event fields.
3. Normalize missing values.
4. Build a readable security notification.
5. Send the notification through SMTP.

Optional later extension:

- add local AI analysis with Ollama,
- enrich the event with additional information,
- correlate Event ID 4740 with previous Event ID 4625 events.

---

## Expected e-mail content

Example:

```text
SECURITY ALERT — Active Directory Account Lockout

Host: LAB-DC1
Locked account: test.user
Domain: CYBER
Event ID: 4740
Caller Computer: LAB-W11-01
Wazuh Rule ID: XXXXX
Severity: X

Description:
The Active Directory account test.user was locked after multiple failed
authentication attempts.

Recommended verification:
- confirm whether the user entered an incorrect password,
- verify Caller Computer Name,
- check recent Event ID 4625 events,
- verify whether the account is used by a service, scheduled task,
  mapped drive or saved credentials.
```

---

## Test plan

### Test 1 — Normal account lockout

Generate several invalid authentication attempts using a test domain account.

Expected result:

- AD locks the account.
- Event ID 4740 appears in the Security log.
- Wazuh detects the event.
- n8n receives the webhook.
- an e-mail alert is delivered.

---

### Test 2 — Validate Caller Computer Name

Generate the failed authentication attempts from a known Windows workstation.

Expected result:

The alert should contain the workstation responsible for the authentication attempts.

---

### Test 3 — Verify Wazuh event fields

Compare:

- Windows Event Viewer
- Wazuh raw event
- Wazuh alert JSON
- n8n webhook input

Expected result:

The important event fields should remain available through the complete pipeline.

---

### Test 4 — Verify e-mail formatting

Confirm that the notification clearly shows:

- account name,
- host,
- domain,
- caller computer,
- Event ID,
- Wazuh Rule ID,
- timestamp.

---

## Troubleshooting scenarios to consider

An account lockout does not automatically mean an attack.

Possible causes include:

- user repeatedly entered the wrong password,
- old password stored in Windows Credential Manager,
- disconnected RDP session,
- mapped network drive,
- scheduled task using outdated credentials,
- Windows service using a domain account,
- mobile device or application using an old password,
- repeated authentication attempts from another workstation.

The alert should therefore provide enough information for the administrator to investigate the source.

---

## Out of scope

The following are intentionally **not included** in this stage:

- Wazuh Active Response
- automatic account disabling
- automatic account unlocking
- automatic IP blocking
- incident response automation
- brute-force correlation based on multiple Event ID 4625 events

These features can be implemented in later projects.

---

## Future development

Possible next steps:

### 06 — Failed Logon Correlation

Correlate multiple Windows Event ID `4625` events within a defined time window.

Example:

```text
5 failed logons from the same source within 120 seconds
```

### 07 — Wazuh Active Response

Automatically respond to a detected security event in the LAB environment.

Possible actions:

- temporary IP blocking,
- temporary user account action,
- automated response script.

---

## Repository structure

Suggested location:

```text
home-it-lab/
└── wazuh/
    ├── configs/
    ├── docs/
    │   ├── 01-architecture.md
    │   ├── 02-failed-logon-default-rule.md
    │   ├── 03-custom-rule-n8n-integration.md
    │   ├── 04-n8n-smtp-integration.md
    │   └── 05-ad-account-lockout-detection.md
    ├── screenshots/
    └── scripts/
```

---

## Definition of Done

The project will be considered complete when:

- [ ] AD Account Lockout Policy is configured in the LAB
- [ ] test user can be locked by invalid authentication attempts
- [ ] Event ID 4740 is visible on the Domain Controller
- [ ] Wazuh receives Event ID 4740
- [ ] custom Wazuh rule detects the event
- [ ] n8n receives the alert
- [ ] e-mail notification contains the locked user
- [ ] e-mail notification contains Caller Computer Name
- [ ] screenshots are added to the repository
- [ ] final configuration is documented
- [ ] testing results are described

---

## Project objective for portfolio

This project demonstrates:

- Windows Security Event monitoring
- Active Directory security auditing
- Wazuh custom rule configuration
- SIEM event handling
- webhook integration
- n8n automation
- SMTP alerting
- basic incident investigation workflow

The project is designed as a practical Home IT Lab implementation rather than a production-ready SOC solution.
