import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    // Slot symbols
    readonly property var symbols: [
        // Common
        {
            icon: "apple-filled",
            label: "Apple",
            weight: 30
        },
        {
            icon: "lemon-2-filled",
            label: "Lemon",
            weight: 29
        },
        {
            icon: "mushroom-filled",
            label: "Mushroom",
            weight: 28
        },
        {
            icon: "cherry-filled",
            label: "Cherry",
            weight: 27
        },
        {
            icon: "melon-filled",
            label: "Melon",
            weight: 26
        },
        {
            icon: "seedling-filled",
            label: "Seedling",
            weight: 25
        },
        {
            icon: "bone-filled",
            label: "Bone",
            weight: 24
        },
        {
            icon: "butterfly-filled",
            label: "Butterfly",
            weight: 23
        },
        {
            icon: "bug-filled",
            label: "Bug",
            weight: 22
        },
        {
            icon: "fish-bone-filled",
            label: "Fish",
            weight: 21
        },
        {
            icon: "bell-filled",
            label: "Bell",
            weight: 20
        },
        {
            icon: "pizza-filled",
            label: "Pizza",
            weight: 19
        },
        {
            icon: "flame-filled",
            label: "Flame",
            weight: 18
        },
        {
            icon: "alien-filled",
            label: "Alien",
            weight: 17
        },
        {
            icon: "star-filled",
            label: "Star",
            weight: 16
        },
        {
            icon: "bomb-filled",
            label: "Bomb",
            weight: 15
        },
        {
            icon: "flare-filled",
            label: "Flare",
            weight: 14
        },
        {
            icon: "trophy-filled",
            label: "Trophy",
            weight: 13
        },
        // Less common
        {
            icon: "clover-filled",
            label: "Clover",
            weight: 12
        },
        {
            icon: "confetti-filled",
            label: "Confetti",
            weight: 11
        },
        {
            icon: "cannabis-filled",
            label: "Cannabis",
            weight: 10
        },
        {
            icon: "sun-filled",
            label: "Sun",
            weight: 9
        },
        {
            icon: "moon-filled",
            label: "Moon",
            weight: 8
        },
        {
            icon: "meteor-filled",
            label: "Meteor",
            weight: 7
        },
        {
            icon: "ghost-3-filled",
            label: "Ghost",
            weight: 6
        },
        {
            icon: "poo-filled",
            label: "Poo",
            weight: 5
        },
        // Rare
        {
            icon: "heart-filled",
            label: "Heart",
            weight: 4
        },
        {
            icon: "bolt-filled",
            label: "Bolt",
            weight: 3
        },
        {
            icon: "diamond-filled",
            label: "Diamond",
            weight: 2
        },
        // HAKARI DOMAIN EXPANSION SKIBIDI DOP DOP YES YES
        {
            icon: "play-card-7-filled",
            label: "7",
            weight: 1
        }
    ]

    // Game state
    property int reel0: pluginApi?.pluginSettings?.reel0 ?? 0
    property int reel1: pluginApi?.pluginSettings?.reel1 ?? 0
    property int reel2: pluginApi?.pluginSettings?.reel2 ?? 0
    property bool spinning: false
    property string lastResult: "" // "jackpot" | "win" | "smallwin" | "loss"
    property int spinSerial: 0 // increments every spin so Panel always sees a change
    // Pre-picked results, revealed reel-by-reel as each stops
    property int pendingReel0: 0
    property int pendingReel1: 0
    property int pendingReel2: 0
    property int credits: pluginApi?.pluginSettings?.credits ?? 15
    property int totalSpins: pluginApi?.pluginSettings?.totalSpins ?? 0
    property int totalWins: pluginApi?.pluginSettings?.totalWins ?? 0

    // Weighted random pick
    function weightedPick() {
        var total = 0;
        for (var i = 0; i < symbols.length; i++)
            total += symbols[i].weight;
        var r = Math.random() * total;
        var acc = 0;
        for (var j = 0; j < symbols.length; j++) {
            acc += symbols[j].weight;
            if (r < acc)
                return j;
        }
        return symbols.length - 1;
    }

    // Spin
    function spin() {
        if (spinning)
            return;
        if (credits <= 0) {
            ToastService.showError("No credits left! Reset to play again.");
            return;
        }
        // Pre-pick all three results now so each reel can reveal its
        // correct symbol the moment it stops, not after all three land
        pendingReel0 = weightedPick();
        pendingReel1 = weightedPick();
        pendingReel2 = weightedPick();
        spinning = true;
        credits -= 1;
        totalSpins += 1;
        spinTimer.restart();
    }

    // Called by Panel staggered timers as each reel stops
    function landReel(reelIdx) {
        if (reelIdx === 0)
            reel0 = pendingReel0;
        else if (reelIdx === 1)
            reel1 = pendingReel1;
        else if (reelIdx === 2)
            reel2 = pendingReel2;
    }

    function landReels() {
        // All reels have already been assigned by landReel() calls.
        // Just resolve the result.
        var s0 = symbols[reel0].label;
        var s1 = symbols[reel1].label;
        var s2 = symbols[reel2].label;

        var result;
        if (s0 === "7" && s1 === "7" && s2 === "7") {
            result = "jackpot";
            credits += 77;
            totalWins += 1;
            ToastService.showNotice("JACKPOT! +77 credits");
        } else if (s0 === s1 && s1 === s2) {
            result = "win";
            credits += 5;
            totalWins += 1;
            ToastService.showNotice("Three " + s0 + "s! +5 credits");
        } else if (s0 === s1 || s1 === s2 || s0 === s2) {
            result = "smallwin";
            credits += 2;
            totalWins += 1;
            ToastService.showNotice("Two of a kind! +2 credits");
        } else {
            result = "loss";
        }

        spinning = false;
        lastResult = result;
        spinSerial += 1;
        saveState();
    }

    function resetCredits() {
        if (credits > 0)
            return;
        credits = 15;
        lastResult = "";
        spinSerial = 0;
        saveState();
        ToastService.showNotice("Credits reset to 15");
    }

    function saveState() {
        if (!pluginApi)
            return;
        pluginApi.pluginSettings.credits = credits;
        pluginApi.pluginSettings.totalSpins = totalSpins;
        pluginApi.pluginSettings.totalWins = totalWins;
        pluginApi.pluginSettings.reel0 = reel0;
        pluginApi.pluginSettings.reel1 = reel1;
        pluginApi.pluginSettings.reel2 = reel2;
        pluginApi.saveSettings();
    }

    // Staggered reel timers (live in Main so they work panel-open or closed)
    // Reel 0 stops first, then 1, then 2. Each reveals its result on stop.
    // Total duration 600+400+300 = 1300ms matches Panel's visual stagger.
    Timer {
        id: spinTimer // kept as spinTimer so spin() can call spinTimer.restart()
        interval: 600
        repeat: false
        onTriggered: {
            root.landReel(0);
            stagger1.restart();
        }
    }
    Timer {
        id: stagger1
        interval: 400
        repeat: false
        onTriggered: {
            root.landReel(1);
            stagger2.restart();
        }
    }
    Timer {
        id: stagger2
        interval: 300
        repeat: false
        onTriggered: {
            root.landReel(2);
            root.landReels();
        }
    }

    // IPC
    // Timer to delay spin until after the panel has had time to open
    Timer {
        id: ipcSpinDelay
        interval: 350
        repeat: false
        onTriggered: root.spin()
    }

    IpcHandler {
        target: "plugin:slot-machine"

        function spin() {
            if (!pluginApi)
                return;
            if (pluginApi.panelOpenScreen) {
                // Panel already open — spin immediately
                root.spin();
            } else {
                // Panel closed — open it first then spin after delay
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen);
                });
                ipcSpinDelay.restart();
            }
        }

        function toggle() {
            if (!pluginApi)
                return;
            pluginApi.withCurrentScreen(screen => {
                pluginApi.togglePanel(screen);
            });
        }

        function reset() {
            root.resetCredits();
        }
    }

    Component.onCompleted: {
        Logger.i("SlotMachine", "Plugin loaded. Credits:", credits);
    }
}
