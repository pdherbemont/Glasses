var Experimental = new Object();

Experimental.HUDController = new Object();

Experimental.HUDController.init = function()
{
    Experimental.HUDController.resetHudPosition();
}

Experimental.HUDController.resetHudPosition =  function resetHudPosition()
{
    var hud = document.getElementById('draggable-controls');
    var marginBottom = 100;
    var bodyWidth = parseInt(document.body.clientWidth, 10);
    var bodyHeight = parseInt(document.body.clientHeight, 10);
    var hudWidth = parseInt(hud.clientWidth, 10);
    var hudHeight = parseInt(hud.clientHeight, 10);
    
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
    return;
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
        window.clearTimeout(timer);
    timer = window.setTimeout(function (){playlist.style.top = - (selectionIndex - 7) * (25) + "px"; timer = null;}, 0);
    
}

var hideTimer = null;
function hidePlaylist()
{
    var elmt = document.getElementById("more");
    if (elmt)
        elmt.addClassName("hidden");
    hideTimer = null;
}

function onKeyDown(event)
{
    var elmt = document.getElementById("more");
    elmt.removeClassName("hidden");
    
    if (hideTimer)
        window.clearTimeout(hideTimer);
    
    // hideTimer = window.setTimeout(function () { hidePlaylist(); }, 6000);
    var handled = window.windowController.navigationController.currentView.keyDown(event);
    switch (event.keyCode) {
        case Global.EventKey.Enter:
            hidePlaylist();
            break;
        case Global.EventKey.LeftArrow:
            if (!handled)
                hidePlaylist();
            break;
    }
}
