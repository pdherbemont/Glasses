var Experimental = new Object();

Experimental.HUDController = new Object();

Experimental.HUDController.init = function()
{
    window.windowController.navigationController.styleUsesScrollBar = false;
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
    
    var handled = window.windowController.navigationController.currentView.keyDown(event);
    switch (event.keyCode) {
        case Lunettes.EventKey.Enter:
            hidePlaylist();
            break;
        case Lunettes.EventKey.LeftArrow:
            if (!handled)
                hidePlaylist();
            break;
    }
}
