local drug = {}
drug[1] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "healP",
            ["num"] = 0.25
        }
    },
    ["iconId"] = 4001,
}
drug[2] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "energy",
            ["num"] = 300
        },
        {
            ["type"] = "healP",
            ["num"] = 0.5
        }
    },
    ["iconId"] = 4101,
}
drug[3] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "healP",
            ["num"] = 1
        }
    },
    ["iconId"] = 4201,
}
drug[4] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "atk",
            ["num"] = 10
        }
    },
    ["iconId"] = 3801,
    ["siconId"] = 3802,
}
drug[5] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "atk",
            ["num"] = 20
        }
    },
    ["iconId"] = 3801,
    ["siconId"] = 3802,
}
drug[6] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "spd",
            ["num"] = 50
        }
    },
    ["iconId"] = 3701,
    ["siconId"] = 3702,
}
drug[7] = {
    ["stage"] = 1,
    ["effect"] = {
        {
            ["type"] = "crit",
            ["num"] = 40
        }
    },
    ["iconId"] = 3901,
    ["siconId"] = 3902,
}
return drug