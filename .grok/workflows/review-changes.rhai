let meta = #{
    name: "review-changes",
    description: "Review a diff across correctness, errors, and five-attribute risks",
    when_to_use: "Need a bounded read-only review of a path, branch, or diff",
    phases: [
        #{ title: "Review", detail: "one reviewer per dimension" },
        #{ title: "Verify", detail: "one skeptic per finding" },
    ],
};

let findings_schema = #{
    "type": "object", "required": ["findings"],
    "properties": #{
        "findings": #{ "type": "array", "maxItems": 8, "items": #{
            "type": "object", "required": ["file", "issue"],
            "properties": #{
                "file": #{ "type": "string" },
                "issue": #{ "type": "string" },
            },
        }},
    },
};
let verdict_schema = #{
    "type": "object", "required": ["real", "reason", "evidence"],
    "properties": #{
        "real": #{ "type": "boolean" },
        "reason": #{ "type": "string" },
        "evidence": #{ "type": "string" },
    },
};

let target = if args == () { () } else { args.target };
if target == () { pause("verification", "Pass args.target — the diff, branch, or path to review."); }

phase("Review");
let dimensions = ["correctness bugs", "error handling gaps", "resilience security safety privacy reliability"];
let jobs = [];
for d in dimensions {
    let p = "Review ";
    p += target;
    p += " for ";
    p += d;
    p += ". Use read_file, grep, and git diff. Do not answer from memory. ";
    p += "Report at most 8 concrete findings as {file, issue}. ";
    p += "An empty list is valid only after you have read the code.";
    jobs.push(#{
        prompt: p,
        label: "review-dim",
        capability_mode: "read-only",
        output_schema: findings_schema,
    });
}
let results = parallel(jobs);

let findings = [];
for r in results {
    if r != () && r.success && r.output.findings != () {
        for f in r.output.findings { findings.push(f); }
    }
}
if findings.len() == 0 { complete(#{ summary: "No findings.", confirmed: [] }); }

phase("Verify");
let vjobs = [];
for f in findings {
    let vp = "Adversarially verify this review finding by reading the shipped code: \"";
    vp += f.issue;
    vp += "\" in ";
    vp += f.file;
    vp += ". Set real=true only with concrete evidence you independently inspected. Otherwise real=false.";
    vjobs.push(#{
        prompt: vp,
        label: "verify-item",
        capability_mode: "read-only",
        output_schema: verdict_schema,
    });
}
let verdicts = parallel(vjobs);

let confirmed = [];
let i = 0;
for v in verdicts {
    if v != () && v.success && v.output.real == true
        && v.output.evidence != () && v.output.evidence != "" {
        confirmed.push(findings[i]);
    }
    i += 1;
}
let n = confirmed.len().to_string();
let t = findings.len().to_string();
let msg = n;
msg += "/";
msg += t;
msg += " findings survived verification";
log(msg);
complete(#{ summary: n + " confirmed findings", confirmed: confirmed });
