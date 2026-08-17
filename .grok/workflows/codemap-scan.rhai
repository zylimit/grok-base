let meta = #{
    name: "codemap-scan",
    description: "Read CODEMAP and list modules for a large-repo refresh",
    when_to_use: "Need a bounded CODEMAP module list before explore fan-out",
    phases: [ #{ title: "Map" } ],
};

let map_schema = #{
    "type": "object",
    "required": ["modules"],
    "properties": #{
        "modules": #{ "type": "array", "maxItems": 8, "items": #{
            "type": "object",
            "required": ["path", "duty"],
            "properties": #{
                "path": #{ "type": "string" },
                "duty": #{ "type": "string" },
            },
        }},
    },
};

let root = if args == () { () } else { args.root };
if root == () { pause("verification", "Pass args.root — repository root that may contain docs/CODEMAP.md."); }

phase("Map");
let mp = "In ";
mp += root;
mp += " use read_file on docs/CODEMAP.md if it exists. ";
mp += "List at most 8 modules as {modules:[{path,duty}]}. ";
mp += "An empty modules list is valid only after you attempted to read the file.";
let mapped = agent(mp, #{
    label: "codemap",
    capability_mode: "read-only",
    output_schema: map_schema,
});
if mapped != () && mapped.success && mapped.output.modules != () {
    complete(#{ summary: "codemap scan ok", modules: mapped.output.modules });
}
complete(#{ summary: "scan incomplete", modules: [] });
