/**
 * @constructor
 */

var HUDController = function ()
{

}

HUDController.prototype.init = function()
{
    window.windowController.navigationController.elementStyleUsesScrollBar = false;
    this.resetHudPosition();

    schedulePlaylistHidding();
}

HUDController.prototype.resetHudPosition =  function resetHudPosition()
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

window.hudController = new HUDController();


/* Playlist */

var timer = null;
var hideTimer = null;
function hidePlaylist()
{
    var name = "show-playlist";
    document.getElementById("more").removeClassName("visible");
    document.body.removeClassName(name);
}

function schedulePlaylistHidding()
{
    if (hideTimer)
        window.clearTimeout(hideTimer);
    hideTimer = window.setTimeout(hidePlaylist, 5000);
}

function showPlaylist()
{
    var name = "show-playlist";
    document.getElementById("more").addClassName("visible");
    document.body.addClassName(name);
    schedulePlaylistHidding();
}

function onKeyDown(event)
{
    showPlaylist();

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
