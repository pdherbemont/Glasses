var HUDController = new Object();

HUDController.init = function()
{
    resetHudPosition();	
}

function resetHudPosition()
{
    var hud = document.getElementById('draggable-controls');
    var marginBottom = 100;
    var bodyWidth = parseInt(document.body.clientWidth);
    var bodyHeight = parseInt(document.body.clientHeight);
    var hudWidth = parseInt(hud.clientWidth);
    var hudHeight = parseInt(hud.clientHeight);
    
    hud.style.left = (bodyWidth - hudWidth) / 2 + 'px';
    hud.style.top = (bodyHeight - hudHeight - marginBottom) + 'px';
}

/* Playlist */
var selectionIndex = 0;
var timer = null;
function removeCurrentSelection()
{
    var item = document.getElementById("tableItem" + selectionIndex);
    item.removeClassName("selected");
    
}
function gotoCurrentSelection()
{
    if (selectionIndex < 0)
        selectionIndex = 0;
    
    var item = document.getElementById("tableItem" + selectionIndex);
    var playlist = document.getElementById("playlist");
    if (!item) {
        selectionIndex--;
        if (selectionIndex > 0)
            gotoCurrentSelection();
        else
            selectionIndex = 0;
        return;
    }
    
    item.addClassName("selected");
    
    if (timer)
        clearTimeout(timer);
    timer = setTimeout(function (){playlist.style.top = - (selectionIndex - 7) * (25) + "px"; timer = null;}, 0);
    
}

var hideTimer = null;
function hidePlaylist()
{
    var elmt = document.getElementById("more");
    elmt.addClassName("hidden");
    hideTimer = null;
}

function onKeyDown(event)
{
    var elmt = document.getElementById("more");
    elmt.removeClassName("hidden");
    
    if (hideTimer)
        clearTimeout(hideTimer);
    
    hideTimer = setTimeout(function () { hidePlaylist(); }, 1000);
    
    switch (event.keyCode) {
        case 40: // Up
            removeCurrentSelection();
            selectionIndex++;
            gotoCurrentSelection();
            break;
        case 38: // Down
            removeCurrentSelection();
            selectionIndex--;
            gotoCurrentSelection();
            break;
        case 13: // Enter
            window.PlatformView.playMediaAtIndex_(selectionIndex);
            elmt.addClassName("hidden");
            break;
        case 00: // Escape
            break;
    }
}
