# 08 — File Server Security Monitoring (Windows Failover Cluster + Wazuh)

> **Status:** ✅ Core detection verified in the lab · 🟡 Multi-folder coverage and failover validation pending  
> **Environment:** Windows Server 2025 · Active Directory · Failover Cluster · SMB · NTFS · TrueNAS iSCSI · Wazuh 4.14.8  
> **Date of validated tests:** 27–28 October 2026

## 1. Project objective

Build a practical file-server monitoring scenario for a fictional company, **CYFROWY POLSAT**, in the `cyber.local` lab domain. Detect file creation, content changes, and deletion on a clustered SMB file server, and identify the domain account responsible for a deletion.

**Validated outcome:** Wazuh File Integrity Monitoring (FIM) operating in **WhoData** mode generated a **File deleted** alert for `fvat10.txt` and identified `akowalska` as the user. This is a confirmed lab result for the `Ksiegowosc` folder on **FS1**, not yet proof of high availability of monitoring after failover.

## 2. Lab architecture

```text
LAB-W11-1 (CYBER\akowalska)
      |
      | SMB: \\LAB-FILES\CYFROWY-POLSAT
      v
LAB-FILES (clustered file-server role)
      |
      +-- FS1: 10.1.201.221  [Wazuh agent 010]
      +-- FS2: 10.1.201.222  [Wazuh agent 011]
      |
      +-- Shared disk S: (CLUSTER-DATA, ~30 GB)
             |
             +-- S:\CYFROWY POLSAT\...
                  (TrueNAS iSCSI backing storage)

FS1/FS2 agents ---> Wazuh Manager 10.1.201.201 ---> Dashboard
```

| Component | Configuration |
|---|---|
| AD domain | `cyber.local` (NetBIOS `CYBER`) |
| AD company OU | `CYFROWY POLSAT` |
| Cluster | `LAB-CLUSTER` |
| Clustered file-server role | `LAB-FILES` |
| SMB share | `\\LAB-FILES\CYFROWY-POLSAT` |
| Share path | `S:\CYFROWY POLSAT` |
| Shared disk | `S:` / `CLUSTER-DATA`, approximately 30 GB; backed by TrueNAS iSCSI |
| Wazuh Manager | `10.1.201.201` |
| FS1 / Wazuh agent | `10.1.201.221` / ID `010` |
| FS2 / Wazuh agent | `10.1.201.222` / ID `011` |
| Windows | Windows Server 2025 Standard |
| Wazuh agent version | `4.14.8` |

**Cluster note:** The shared `S:` disk is available to the active owner of the clustered role. Configure and validate FIM on **each possible owner**, and test behavior after the disk moves; a working FIM alert on FS1 alone does not establish monitoring continuity through failover.

## 3. Fictional company structure and access control

### Active Directory accounts

| Department | Test accounts | AD security group |
|---|---|---|
| Accounting (`Ksiegowosc`) | `akowalska`, `pmalinowski` | `GG_W08_Ksiegowosc_RW` |
| HR (`Kadry`) | `enowicka`, `mlis` | `GG_W08_Kadry_RW` |
| Production (`Produkcja`) | `tzielinski`, `pkrawczyk` | `GG_W08_Produkcja_RW` |
| Management (`Zarzad`) | `awisniewski` | `GG_W08_Zarzad_RW` |
| IT | `kmazur` | `GG_W08_IT_RW` |
| Wazuh tests (`Testy_Wazuh`) | `jtestowy` | `GG_W08_Testy_Wazuh_RW` |

Nine fictional users were created in AD. A test login as `akowalska` on Windows 11 succeeded.

### Directory structure

```text
S:\CYFROWY POLSAT\
├── IT\
├── Kadry\
├── Ksiegowosc\
├── Produkcja\
├── Public\
├── Testy_Wazuh\
└── Zarzad\
```

- Departmental security groups have **Modify** access to their respective folders.
- `SYSTEM` and `BUILTIN\Administrators` retain **FullControl**.
- `CYBER\Domain Users` have **Modify** on `Public`.
- **Access-Based Enumeration (ABE)** is enabled on the clustered SMB share.
- Observed result: `akowalska` browsing the share saw `Ksiegowosc` and `Public`; `Kadry` was not shown. ABE is a visibility feature; NTFS permissions enforce access.

Example NTFS verification:

```powershell
(Get-Acl 'S:\CYFROWY POLSAT\Ksiegowosc').Access |
  Format-Table IdentityReference, FileSystemRights, IsInherited -AutoSize
```

## 4. Windows Security auditing (supporting telemetry)

File-system auditing and a SACL were configured on the active file-server node for `Ksiegowosc`. The targeted audit trustee was `CYBER\GG_W08_Ksiegowosc_RW`; monitored rights included `Delete` and `DeleteSubdirectoriesAndFiles`, with successful operations audited and inheritance enabled for children.

Verify the policy on **both** cluster nodes:

```powershell
auditpol /get /subcategory:"File System"
```

During testing, Windows Security recorded:

| Event ID | Meaning | Interpretation |
|---|---|---|
| `4659` | Handle requested with intent to delete | **Intent**, not proof of a completed deletion |
| `4663` with DELETE (`0x10000`) | DELETE right exercised | May occur during rename or other file operations; **not independently conclusive** |
| `4660` | Object deleted | Helpful confirmation, but may lack object name and require correlation with another event/handle |

Examples observed for `CYBER\akowalska` include `WAZUH-DELETE-600.txt`, `WAZUH-DELETE-700.txt` (4663), and `fva7.txt` (4659). In the `fva7.txt` test, the Windows event was sent to Wazuh Manager's JSON archive:

```json
{
  "eventID": "4659",
  "user": "akowalska",
  "file": "\\\\Device\\\\HarddiskVolume7\\\\CYFROWY POLSAT\\\\Ksiegowosc\\\\fva7.txt",
  "access": "0x10080"
}
```

**Caution:** A previous test created `FAKTURA-TEST-DELETE-002.txt.txt` because Windows Explorer hid known filename extensions. Enable *View → Show → File name extensions* when conducting manual tests.

## 5. Wazuh agent collection

Wazuh Windows agents were enrolled as `FS1` (010) and `FS2` (011). On FS1, the agent status was `connected` with an established TCP connection to `10.1.201.201:1514`. The agent log reported that it was analyzing the `Security` channel.

For the lab's targeted Windows Security collection, the `ossec.conf` block was:

```xml
<localfile>
  <location>Security</location>
  <log_format>eventchannel</log_format>
  <query>Event/System[(EventID=4659 or EventID=4660 or EventID=4663 or EventID=4670)]</query>
</localfile>
```

**Scope warning:** This is a *test-specific replacement* for the Security channel collector. If used as the only Security block, it does **not** collect other important Windows events (such as authentication or AD activity). Preserve broader collection in any general-purpose monitoring configuration and avoid overlapping/duplicated localfile collectors.

### Evidence of manager reception

While `logall_json` was temporarily enabled, the following confirmed that `fva7.txt` event ID `4659` arrived from agent 010:

```bash
sudo jq -c '
  select(.agent.id == "010")
  | select((.data.win.eventdata.objectName // "") | contains("fva7.txt"))
  | {
      timestamp,
      eventID: .data.win.system.eventID,
      user: .data.win.eventdata.subjectUserName,
      file: .data.win.eventdata.objectName,
      access: .data.win.eventdata.accessMask
    }
' /var/ossec/logs/archives/archives.json
```

The archive is **not the same as Threat Hunting alerts**: an event can arrive at the manager without triggering a rule above the alerting threshold. For production, avoid leaving verbose archiving enabled without a defined retention/storage plan.

## 6. FIM: verified file lifecycle detection

### Phase A — realtime

Initially, FIM was enabled for the Accounting folder using:

```xml
<!-- Inside the existing <syscheck> section on FS1 -->
<directories check_all="yes" realtime="yes">S:\CYFROWY POLSAT\Ksiegowosc</directories>
```

The Wazuh Dashboard displayed the following for `faktura9.txt`:

- **File added to the system** (`syscheck_new_entry`)
- **Integrity checksum changed**
- **File deleted** (`syscheck_deleted`, rule ID `553`, level `7`)

The realtime event confirms a monitored file lifecycle change, but does not necessarily identify the responsible user.

### Phase B — WhoData (current verified FS1 configuration)

The realtime entry was **replaced** with this line inside the existing `<syscheck>` section:

```xml
<directories check_all="yes" whodata="yes">S:\CYFROWY POLSAT\Ksiegowosc</directories>
```

Do not add an unnecessary duplicate `<syscheck>` section or duplicate entry for the same folder. Restart the Windows agent after editing:

```powershell
Restart-Service WazuhSvc
Get-Content 'C:\Program Files (x86)\ossec-agent\ossec.log' -Tail 120 |
  Select-String -Pattern 'whodata|syscheck|audit|ERROR|WARNING'
```

Verified FS1 agent messages included:

```text
File integrity monitoring real-time Whodata engine started.
Monitoring path: 's:\cyfrowy polsat\ksiegowosc', with options '... | whodata'.
```

### WhoData test: actual file deletion and user attribution

A test account `CYBER\akowalska` deleted `fvat10.txt` over SMB from `Ksiegowosc`. Wazuh Dashboard showed:

| Field | Verified value |
|---|---|
| `agent.name` | `FS1` |
| `syscheck.path` | `s:\cyfrowy polsat\ksiegowosc\fvat10.txt` |
| `syscheck.event` | `deleted` |
| `syscheck.mode` | `whodata` |
| `syscheck.audit.user.name` | `akowalska` |
| `syscheck.audit.user.id` | `S-1-5-21-86986582-4202049309-2926810666-1116` |
| `syscheck.audit.process.id` | `4` |
| Rule | `553` — `File deleted.` |
| Recorded manager timestamp | `2026-10-27T23:41:04.386+0000` (28 October, 00:41:04 CET) |

Evidence captured from `/var/ossec/logs/alerts/alerts.json`:

```json
{
  "timestamp": "2026-10-27T23:41:04.386+0000",
  "file": "s:\\cyfrowy polsat\\ksiegowosc\\fvat10.txt",
  "event": "deleted",
  "mode": "whodata",
  "audit": {
    "user": {
      "id": "S-1-5-21-86986582-4202049309-2926810666-1116",
      "name": "akowalska"
    },
    "process": { "id": "4" }
  }
}
```

`process.id = 4` represents the Windows **System** process on the file server (consistent with SMB operations); it is not evidence of the client application that initiated the deletion.

**Result:** file deletion **and the responsible AD account** were verified together in a FIM WhoData alert on FS1.

### Retrieve WhoData deletions

```bash
sudo jq -c '
  select(.agent.id == "010")
  | select(.syscheck.event == "deleted")
  | {
      timestamp,
      file: .syscheck.path,
      user: .syscheck.audit.user.name,
      mode: .syscheck.mode,
      process_id: .syscheck.audit.process.id,
      rule: .rule.id
    }
' /var/ossec/logs/alerts/alerts.json | tail -20
```

## 7. Custom rule development — not yet validated

During experimentation, a custom `4659` alert rule was proposed. A **duplicate rule ID `100800`** was discovered: the ID already existed in `100100-MITRE_TECHNIQUES_FROM_SYSMON_EVENT1.xml`. An alternative ID `110800` was added for the file-server rule, but **successful rule matching in `wazuh-logtest` and live deployment were not confirmed**.

Before any future deployment:

1. Remove the obsolete `100800` file-server rule from `local_rules.xml`; **do not alter** the existing Sysmon rule with that ID.
2. Check that `110800` is unique and only the intended file-server rule remains.
3. Run `sudo /var/ossec/bin/wazuh-analysisd -t` and a sample-event test with `sudo /var/ossec/bin/wazuh-logtest`.
4. Restart the manager only after validation.

The pre-existing warnings for rules `900177–900186` referencing missing group `sysmon_event_7` are a **separate issue** and should be tracked independently.

**Note:** Because FIM WhoData already emits a confirmed deletion alert (rule 553), a custom Windows Security `4659` rule is optional, and its label must clearly say **delete intent**, not **file deleted**.

## 8. Verification checklist

- [x] AD: fictional organization and test users created
- [x] Clustered SMB share available at `\\LAB-FILES\CYFROWY-POLSAT`
- [x] Department ACLs configured and Accounting ACL inspected
- [x] ABE confirmed for Accounting user
- [x] Windows Security audit/SACL confirmed for Accounting
- [x] Wazuh agents FS1 and FS2 enrolled and active
- [x] Windows `4659` received from FS1 in `archives.json`
- [x] FIM realtime `added`, `modified`, `deleted` observed on FS1
- [x] WhoData `deleted` + username `akowalska` confirmed on FS1
- [ ] Clean up the duplicate custom `100800` rule and validate `110800` if retained
- [ ] Extend FIM/WhoData to other department folders
- [ ] Verify FS2 FIM and SACL requirements after a controlled failover
- [ ] Test active-node transitions, monitoring continuity, and recovery
- [ ] Design and test mass-delete correlation and alert thresholds
- [ ] Define archive retention and disable temporary `logall_json` when no longer needed

## 9. Next steps

**A. Broaden coverage carefully.** Add the remaining departmental directories to `<syscheck>` in a controlled manner. Confirm user attribution and audit log volume for each directory. Avoid placing unnecessary FIM watches on unrelated server paths.

**B. Failover test.** Configure and validate monitoring on FS2. Perform a planned `LAB-FILES` role move, verify `S:` availability and active FIM on the new owner, then test new file creation and deletion. Record any monitoring gap during transfer.

**C. Mini-DLP detection.** Prototype an alert for repeated deletions by one account within a short window (for example, 10 deletions within 60 seconds), using actual FIM `deleted` events. Tune thresholds using lab data before considering production use.

**D. Documentation and housekeeping.** Save anonymized screenshots of the Windows Security event, FIM `added` / `deleted` alerts, and the WhoData `audit.user.name` field. Do not include passwords, active secrets, or real employee documents in the repository.

## Screenshots / Dowody działania

Zrzuty z testów znajdują się w katalogu [`screenshots/08-file-server-security-monitoring`](screenshots/08-file-server-security-monitoring/). W plikach pozostawiono widoczne wyłącznie informacje z laboratorium; przed publikacją publiczną sprawdź własne zasady ujawniania nazw hostów, adresacji i kont.

**Najważniejsze dowody:**

- [Struktura OU fikcyjnej firmy](screenshots/08-file-server-security-monitoring/20261016-114153-AD-OU-CYFROWY-POLSAT.png)
- [Foldery i pliki testowe na S:](screenshots/08-file-server-security-monitoring/20261016-120056-Foldery-i-dokumenty.png)
- [Uprawnienia NTFS i dziedziczenie](screenshots/08-file-server-security-monitoring/20261016-122156-NTFS-ACL.png)
- [ABE: Anna widzi wyłącznie Ksiegowosc i Public](screenshots/08-file-server-security-monitoring/20261016-125026-ABE-Ksiegowosc-Public.png)
- [Aktywne agenty FS1 i FS2](screenshots/08-file-server-security-monitoring/20261016-134414-Agenci-FS1-FS2.png)
- [FIM: dodanie pliku](screenshots/08-file-server-security-monitoring/20261027-233505-FIM-Added.png)
- [FIM: usunięcie w realtime](screenshots/08-file-server-security-monitoring/20261027-233637-FIM-Deleted-Realtime.png)
- [WhoData: File deleted](screenshots/08-file-server-security-monitoring/20261027-234147-FIM-Deleted-WhoData.png)
- [WhoData: użytkownik akowalska](screenshots/08-file-server-security-monitoring/20261027-234251-FIM-WhoData-akowalska.png)

**Archiwum wszystkich etapów:** dołączono 33 oryginalnych zrzutów, uporządkowanych chronologicznie.

## 10. Takeaway

A Windows Failover Cluster shared file server can be monitored by Wazuh FIM on its active disk owner. In the tested configuration, WhoData provided evidence not only that `fvat10.txt` was deleted, but also that the action was associated with the domain user **`akowalska`**. Cluster-wide coverage and failover continuity remain the next validation milestones.
