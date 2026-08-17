let meta = #{
    name: "nfr-gate",
    description: "Five-attribute gate: fitness and adr-check then a judge",
    when_to_use: "Before review or release, run NFR machine gates",
    phases: [
        #{ title: "Scan" },
        #{ title: "Judge" },
    ],
};

let scan_schema = #{
    "type": "object",
    "required": ["fitness_ok", "adr_ok", "evidence"],
    "properties": #{
        "fitness_ok": #{ "type": "boolean" },
        "adr_ok": #{ "type": "boolean" },
        "evidence": #{ "type": "string" },
    },
};
let judge_schema = #{
    "type": "object",
    "required": ["verdict", "reason"],
    "properties": #{
        "verdict": #{ "type": "string" },
        "reason": #{ "type": "string" },
    },
};

let path = if args == () { () } else { args.path };
if path == () { pause("verification", "Pass args.path — repository root to gate."); }

phase("Scan");
let sp = "In ";
sp += path;
sp += " run these commands with run_terminal_command and paste full output: ";
sp += "bash .grok/scripts/fitness.sh . ; bash .grok/scripts/adr-check.sh . ; ";
sp += "Return {fitness_ok, adr_ok, evidence}. fitness_ok is true only if fitness printed PASS. ";
sp += "adr_ok is true if adr-check printed nothing to check or PASS. evidence is the raw command output.";
let scan = agent(sp, #{
    label: "nfr-scan",
    capability_mode: "execute",
    output_schema: scan_schema,
});

phase("Judge");
if scan == () || !scan.success || scan.output.evidence == () {
    complete(#{ summary: "BLOCKED: scan produced no usable evidence", verdict: "BLOCKED" });
}
let jp = "You are an NFR gate judge. fitness_ok=";
jp += json_encode(scan.output.fitness_ok);
jp += " adr_ok=";
jp += json_encode(scan.output.adr_ok);
jp += " evidence=";
jp += json_encode(scan.output.evidence);
jp += " Verdict must be PASS, FAIL, or BLOCKED. ";
jp += "No verification command output means BLOCKED, never PASS. ";
jp += "Return {verdict, reason}.";
let judge = agent(jp, #{
    label: "nfr-judge",
    capability_mode: "read-only",
    output_schema: judge_schema,
});
if judge == () || !judge.success || judge.output.verdict == () {
    complete(#{ summary: "BLOCKED: judge produced no verdict", verdict: "BLOCKED" });
}
complete(#{ summary: judge.output.verdict, verdict: judge.output.verdict, reason: judge.output.reason });
