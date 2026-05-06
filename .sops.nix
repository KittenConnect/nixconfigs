let
  machines = {
    # host_poubelle00 = "age1fdp7w6z9mayzm3e9n2a00up45jws53wsqnwk0kc884p5j643ky3snhs7vz";
    # host_stonkstation = "age16462eqs3uc8rvlr5ef7ttvt2qe2gvaha7gf2prhwadfffmvmcdgs5nt22v";
    # host_prodesk = "age1syx48exjgrns9500apf3v4a84gj62fdpy0sqvseax438d9k0y3tqrtfn3t";

    vultr-kit-edge.age = "age1w2cfzf8wm02umpj74tcseqmslhj2cfl9qtkdkcnj5cyvspyhvfxq5lh2gd";
    virtua-kit-edge.age = "age1a2dpax5xwt4855jfpsxh83l6y9uf2804uszhxydqhxwr9hk4a96s42k4e0";

    iguane-kit-rtr.age = "age19qe5ea965hnjv5e9dty2ws5dr375tsh0x4ct0zg6syg82cmlp9wq0l6sgp";
    goog-kit-rtr.age = "age1lwxvl3ts4fqufk99pqyxuf3wdc0exy7x78x0kc49ahwu4krawpdqguxc90";

    aure-home-kitrtr.age = "age1f9c0vpqpafkc0uugm4qnwuw8tr87pt63ar9497auzsz6kker33tq8cs7gw";
    romain-home-kitrtr.age = "age13shuee5uk80wjlhdsl2hlg7n7nv489wxq8r7xy0arh9nkk3lju9qfs0k0x";
    toinux-home-kitrtr.age = "age1fuf8dejemxxlqmsc44frs0xkfzyk4qypyrrdr36g5c3rlmt2fv7qc3ljsl";
  };

  operators = {
    root = {
      age = [
        "age10zyzjhvtp96mzuas9xtykmz0snh03rm2k5q0fzk78cc8fdnd0ehsrsnl7f" # nixifier
        "age1aj2qrwdh88njh3kx695zglvzvdzxggwkkdxdumrlp00pnjtctdws0q8y0c" # stonks
        "age1m7erxk6hmmlar2k9u7gjsjlhgquxww84tfdlank0lv92g20fuydqglqqur" # laptaupe
      ];
    };
  };

  getMachineKeys =
    keyType: machineName:
    if builtins.hasAttr keyType machines.${machineName} then
      if builtins.isList machines.${machineName}.${keyType} then
        machines.${machineName}.${keyType}
      else
        [ machines.${machineName}.${keyType} ]
    else
      [ ];

  getOperatorKeys =
    keyType: ops:
    builtins.foldl' (
      acc: n:
      let
        op = operators.${n};
        opKeys = if builtins.isList op.${keyType} then op.${keyType} else [ op.${keyType} ];
      in
      if (!builtins.hasAttr keyType op) then
        acc
      else
        acc ++ (builtins.filter (k: !(builtins.elem k acc)) opKeys)
    ) [ ] ops;

  mergeKeyGroups = builtins.foldl' (
    acc: machine:
    acc
    // builtins.mapAttrs (
      keyType: machineKeys:
      let
        old = acc.${keyType} or [ ];
      in
      old
      ++ (builtins.filter (k: !(builtins.elem k old)) (
        if builtins.isList machineKeys then machineKeys else [ machineKeys ]
      ))
    ) machine
  ) { };

  mkKeyGroup =
    allowedKeys@{
      age ? { },
      pgp ? { },
      kms ? { },
    }:
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;

        value = allowedKeys.${name};
      }) (builtins.attrNames allowedKeys)
    );

  mkSopsRule =
    {
      path_regex,
      encrypted_regex ? null,
      mac_only_encrypted ? true,
      keyGroups ? [ ],
      allowedKeys ? { }, # can contains : age ? [], pgp ? [], kms ? [],
    }:
    {
      inherit path_regex encrypted_regex mac_only_encrypted;

      key_groups = keyGroups ++ [ (mkKeyGroup allowedKeys) ];
    };

  mkPublicRule =
    path_regex:
    mkSopsRule {
      inherit path_regex;
      # encrypted_regex: ([sS]ecret([-_]key)?|[pP]assword)$
      allowedKeys = mergeKeyGroups ([ operators.root ] ++ (builtins.attrValues machines));

      mac_only_encrypted = true;
    };

  basicRules = map (
    machineName:
    let
      machine = machines.${machineName};
      machineOps = [ "root" ] ++ (machine.operators or [ ]);
    in
    mkSopsRule {
      path_regex = ".secrets/${machineName}([_/][^/]*)?\.(yaml|json|env|ini)$";
      # encrypted_regex: ([sS]ecret([-_]key)?|[pP]assword)$
      allowedKeys.age = (getMachineKeys "age" machineName) ++ (getOperatorKeys "age" machineOps);

      mac_only_encrypted = true;
    }
  ) (builtins.attrNames machines);
in
[
  (mkPublicRule ".secrets/[^/]+\.pub\.(yaml|json|env|ini)$")
  (mkPublicRule ".secrets/public([_/][^/]*)?\.(yaml|json|env|ini)$")
]
++ basicRules
++ [
  (mkSopsRule {
    path_regex = ".secrets/_gitnamed([_/][^/]*)?\.(yaml|json|env|ini)$";
    # encrypted_regex: ([sS]ecret([-_]key)?|[pP]assword)$
    allowedKeys = mergeKeyGroups (
      [ operators.root ]
      ++ (with machines; [
        vultr-kit-edge
        virtua-kit-edge
      ])
    );

    mac_only_encrypted = true;
  })
  (mkPublicRule ".secrets/[^/]+\.(yaml|json|env|ini)$")
]
