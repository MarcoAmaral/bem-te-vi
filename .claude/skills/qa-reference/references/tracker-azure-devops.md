---
id: ref-tracker-azure-devops
---
# Azure DevOps Tracker Reference

> **Read on demand** | Moved out of `/qa-defect` | Part of the `qa-reference` skill

Read this when the team files bugs in Azure DevOps (ADO): the `SystemInfo` field format, uploading evidence as an attachment, the bug field mapping and a filing script. For any other tracker, map the report's fields to that tracker's schema.

---

## SystemInfo field format

Format the output as the `SystemInfo` HTML block:

```html
<b>Application:</b> [AppName] v[version] (Next.js X.Y.Z)<br>
<b>Environment:</b> Local / Dev / Staging / Production<br>
<b>OS:</b> [uname output]<br>
<b>Node.js:</b> vX | <b>npm:</b> X<br>
<b>[key deps]</b><br>
<b>Branch:</b> [branch] | <b>Commit:</b> [hash]
```

---

## Uploading evidence

Then **upload it to the tracker and attach it** — never store a local path in the work item. The
example below uses the Azure DevOps REST API; adapt it to your tracker. Credentials and the
organisation come from the environment, never from the command text:

```python
import json, urllib.request, base64
from pathlib import Path

import os
pat = os.environ["AZURE_DEVOPS_PAT"]          # a personal access token, never committed
org, project = os.environ["ADO_ORG"], os.environ["ADO_PROJECT"]
credentials = base64.b64encode(f":{pat}".encode()).decode()

file_path = Path("docs/qa/evidence/DR-XXX-description.txt")
headers_upload = {"Content-Type": "application/octet-stream", "Authorization": f"Basic {credentials}"}
headers_patch  = {"Content-Type": "application/json-patch+json", "Authorization": f"Basic {credentials}", "If-Match": "*"}

# 1. Upload file content → get permanent ADO URL
upload_req = urllib.request.Request(
    f"https://dev.azure.com/{org}/{project}/_apis/wit/attachments?fileName={file_path.name}&api-version=7.1",
    data=file_path.read_bytes(), headers=headers_upload, method="POST"
)
with urllib.request.urlopen(upload_req) as resp:
    att = json.loads(resp.read())

att_url = att["url"]  # the permanent attachment URL returned by the upload

# 2. Link as AttachedFile relation (+ an evidence field, if your process defines one)
patch = json.dumps([
    {"op": "add", "path": "/relations/-", "value": {
        "rel": "AttachedFile", "url": att_url,
        "attributes": {"comment": "Evidence log — DR-XXX"}
    }},
    # Optional: a custom evidence field of your process, e.g. Custom.Artifacts
    # {"op": "replace", "path": "/fields/Custom.Artifacts", "value": att_url}
]).encode()

urllib.request.urlopen(urllib.request.Request(
    f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/[BUG-ID]?api-version=7.1",
    data=patch, headers=headers_patch, method="PATCH"
))
```

The file appears in the work item's **Attachments tab** (clickable/downloadable). If your process has a custom evidence field, it holds the attachment URL — never a local file path.

---

## Step 2 — ADO Bug Field Mapping

Use this step if the team's tracker is Azure DevOps; otherwise map the same fields to the tracker the repository uses. When filing in ADO, use the **correct field** for each piece of information. Never put everything into `System.Description`.

| DR Template section | ADO API field | Notes |
| --- | --- | --- |
| Expected Result | `System.Description` | HTML. ADO labels this "Description" = what *should* happen |
| Steps to Reproduce + Actual Result | `Microsoft.VSTS.TCM.ReproSteps` | HTML. ADO's dedicated repro field — shown prominently in bug view |
| Reporter Role + Context (test case, activity, SDLC phase, technique or checklist, test data) | `Microsoft.VSTS.TCM.ReproSteps`, above the steps | HTML. ADO records the author in `System.CreatedBy` but not their role, and has no standard context field |
| Environment / OS / versions | `Microsoft.VSTS.TCM.SystemInfo` | HTML. Populated from Step 0 output |
| Build / Commit / Branch | `Microsoft.VSTS.Build.FoundIn` | Plain text. e.g. `"6ec645e (feat/us-24-login)"` |
| Screenshot / log | `AttachedFile` relation, plus a custom evidence field if your process has one (e.g. `Custom.Artifacts`) | The uploaded attachment's URL, never a local path |
| Severity | `Microsoft.VSTS.Common.Severity` | `"1 - Critical"`, `"2 - High"`, `"3 - Medium"`, `"4 - Low"` |
| Priority | `Microsoft.VSTS.Common.Priority` | Integer: `1`, `2`, `3`, `4` |
| Tags | `System.Tags` | Semicolon-separated: `"regression; p1; TC-AUTH-005"` |
| Parent US link | relation `System.LinkTypes.Hierarchy-Reverse` | Always link bug to the parent User Story |

### ADO filing template (Python)

```python
import json, urllib.request, base64

import os
pat = os.environ["AZURE_DEVOPS_PAT"]          # a personal access token, never committed
org, project = os.environ["ADO_ORG"], os.environ["ADO_PROJECT"]
credentials = base64.b64encode(f":{pat}".encode()).decode()
headers = {
    "Content-Type": "application/json-patch+json",
    "Authorization": f"Basic {credentials}"
}

payload = json.dumps([
    {"op": "add", "path": "/fields/System.Title",                        "value": "[Component] – [What failed] when [condition]"},
    {"op": "add", "path": "/fields/System.Description",                  "value": "<b>Expected Result:</b><br>[quote from AC]"},
    {"op": "add", "path": "/fields/Microsoft.VSTS.TCM.ReproSteps",       "value": "<b>Reporter role:</b> ...<br><b>Context:</b> TC-XXX-NNN, test activity, SDLC phase, technique, test data<br><b>Pre-conditions:</b><ol><li>...</li></ol><b>Steps:</b><ol><li>...</li></ol><b>Actual Result:</b><br>[exact output]<br><b>Reproducibility:</b> Always (3/3)"},
    {"op": "add", "path": "/fields/Microsoft.VSTS.TCM.SystemInfo",       "value": "<b>Application:</b> ...<br><b>Node.js:</b> ...<br><b>OS:</b> ..."},
    {"op": "add", "path": "/fields/Microsoft.VSTS.Build.FoundIn",        "value": "abc1234 (branch-name)"},
    {"op": "add", "path": "/fields/Microsoft.VSTS.Common.Severity",      "value": "2 - High"},
    {"op": "add", "path": "/fields/Microsoft.VSTS.Common.Priority",      "value": 1},
    {"op": "add", "path": "/fields/System.Tags",                         "value": "regression; p1; TC-XXX-NNN"},
    {"op": "add", "path": "/fields/System.AssignedTo",                   "value": "[assignee@example.com]"}
]).encode()

req = urllib.request.Request(
    f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/$Bug?api-version=7.1",
    data=payload, headers=headers, method="POST"
)
with urllib.request.urlopen(req) as resp:
    d = json.loads(resp.read())
    bug_id = d["id"]
    print(f"Bug #{bug_id} created")

# Link to parent US
link_payload = json.dumps([{
    "op": "add", "path": "/relations/-",
    "value": {
        "rel": "System.LinkTypes.Hierarchy-Reverse",
        "url": f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/[US-ID]",
        "attributes": {"comment": "Found during QA of US-[ID]"}
    }
}]).encode()
link_req = urllib.request.Request(
    f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/{bug_id}?api-version=7.1",
    data=link_payload,
    headers={**headers, "If-Match": "*"},
    method="PATCH"
)
urllib.request.urlopen(link_req)
print("Linked to parent US ✓")
```
