(function () {
    'use strict';

    var app = document.getElementById('app');
    var proxModesEl = document.getElementById('prox-modes');
    var staffSection = document.getElementById('staff-section');
    var playerListEl = document.getElementById('player-list');
    var closeBtn = document.getElementById('close-btn');
    var refreshBtn = document.getElementById('refresh-btn');

    var state = {
        isOpen: false,
        isStaff: false,
        proximityModes: [],
        currentDistance: 15.0,
        players: [],
    };

    // -- DOM Helpers (safe, no innerHTML) --

    function el(tag, className, text) {
        var node = document.createElement(tag);
        if (className) node.className = className;
        if (text) node.textContent = text;
        return node;
    }

    function clearChildren(parent) {
        while (parent.firstChild) {
            parent.removeChild(parent.firstChild);
        }
    }

    // -- Render Functions --

    function renderProxModes() {
        clearChildren(proxModesEl);
        state.proximityModes.forEach(function (mode) {
            var btn = el('button', 'prox-btn' + (mode.distance === state.currentDistance ? ' active' : ''));

            var nameSpan = el('span', 'prox-name', mode.name);
            var distSpan = el('span', 'prox-dist', mode.distance + 'm');

            btn.appendChild(nameSpan);
            btn.appendChild(distSpan);

            btn.addEventListener('click', function () {
                state.currentDistance = mode.distance;
                fetch('https://nv-radio/setProximity', {
                    method: 'POST',
                    body: JSON.stringify({ distance: mode.distance }),
                });
                renderProxModes();
            });
            proxModesEl.appendChild(btn);
        });
    }

    function renderPlayerList() {
        clearChildren(playerListEl);
        if (state.players.length === 0) {
            var empty = el('div', 'empty-state', 'No players connected');
            playerListEl.appendChild(empty);
            return;
        }

        state.players.forEach(function (player) {
            var item = el('div', 'player-item');

            // Player info
            var info = el('div', 'player-info');
            var name = el('div', 'player-name', '[' + player.source + '] ' + player.name);

            var channels = player.radioChannels && player.radioChannels.length > 0
                ? 'CH ' + player.radioChannels.join(', ')
                : 'No channel';
            var meta = el('div', 'player-meta',
                (player.proximityMode || 'Normal') + ' (' + player.proximity + 'm) \u00B7 ' + channels);

            info.appendChild(name);
            info.appendChild(meta);
            item.appendChild(info);

            // Actions
            var actions = el('div', 'player-actions');

            var moveBtn = el('button', 'action-btn move-btn', 'CH');
            moveBtn.title = 'Move to channel';
            moveBtn.addEventListener('click', function () {
                showInlinePrompt(actions, 'Channel #:', function (val) {
                    var ch = parseInt(val, 10);
                    if (ch && ch > 0) {
                        fetch('https://nv-radio/staffMovePlayer', {
                            method: 'POST',
                            body: JSON.stringify({ targetSource: player.source, channel: ch }),
                        });
                    }
                });
            });

            var proxBtn = el('button', 'action-btn prox-staff-btn', 'Prox');
            proxBtn.title = 'Set proximity';
            proxBtn.addEventListener('click', function () {
                showInlinePrompt(actions, 'Distance:', function (val) {
                    var dist = parseFloat(val);
                    if (dist && dist > 0) {
                        fetch('https://nv-radio/staffSetProximity', {
                            method: 'POST',
                            body: JSON.stringify({ targetSource: player.source, distance: dist }),
                        });
                    }
                });
            });

            var isMuted = player.muted || false;
            var muteBtn = el('button', 'action-btn mute-btn', isMuted ? 'Unmute' : 'Mute');
            muteBtn.title = isMuted ? 'Unmute player' : 'Mute player';
            muteBtn.addEventListener('click', function () {
                var newMuted = !isMuted;
                fetch('https://nv-radio/staffMutePlayer', {
                    method: 'POST',
                    body: JSON.stringify({ targetSource: player.source, mute: newMuted }),
                });
                showToast((newMuted ? 'Muted ' : 'Unmuted ') + player.name);
            });

            actions.appendChild(moveBtn);
            actions.appendChild(proxBtn);
            actions.appendChild(muteBtn);
            item.appendChild(actions);

            playerListEl.appendChild(item);
        });
    }

    function showInlinePrompt(container, label, onSubmit) {
        // Remove any existing prompts
        var existing = document.querySelector('.inline-prompt');
        if (existing) existing.parentNode.removeChild(existing);

        var prompt = el('div', 'inline-prompt');
        var input = document.createElement('input');
        input.type = 'text';
        input.placeholder = label;

        var okBtn = el('button', '', 'OK');

        prompt.appendChild(input);
        prompt.appendChild(okBtn);
        container.appendChild(prompt);
        input.focus();

        function submit() {
            var val = input.value.trim();
            prompt.parentNode.removeChild(prompt);
            if (val) onSubmit(val);
        }

        okBtn.addEventListener('click', submit);
        input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') submit();
            if (e.key === 'Escape') prompt.parentNode.removeChild(prompt);
        });
    }

    function showToast(message) {
        var toast = el('div', 'toast', message);
        document.body.appendChild(toast);
        setTimeout(function () {
            if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 2000);
    }

    // -- NUI Message Handler --

    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.type) return;

        switch (data.type) {
            case 'open':
                state.isOpen = true;
                state.isStaff = data.payload.isStaff || false;
                state.proximityModes = data.payload.proximityModes || [];
                state.currentDistance = data.payload.currentProximity
                    ? data.payload.currentProximity.distance
                    : 15.0;

                app.classList.remove('hidden');
                if (state.isStaff) {
                    staffSection.classList.remove('hidden');
                } else {
                    staffSection.classList.add('hidden');
                }
                renderProxModes();
                renderPlayerList();
                break;

            case 'close':
                state.isOpen = false;
                app.classList.add('hidden');
                break;

            case 'playerList':
                state.players = data.players || [];
                renderPlayerList();
                break;

            case 'actionResult':
                if (data.result && data.result.success) {
                    showToast(data.result.action + ' successful');
                }
                break;
        }
    });

    // -- Close Button --

    closeBtn.addEventListener('click', function () {
        fetch('https://nv-radio/close', { method: 'POST', body: '{}' });
    });

    // -- Refresh Button --

    refreshBtn.addEventListener('click', function () {
        fetch('https://nv-radio/refreshPlayerList', { method: 'POST', body: '{}' });
    });

    // -- Escape Key --

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && state.isOpen) {
            fetch('https://nv-radio/close', { method: 'POST', body: '{}' });
        }
    });
})();
