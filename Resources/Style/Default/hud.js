var HUDController = new Object();

HUDController.init = function() {
    resetHudPosition();	
}

function resetHudPosition() {
    var hud = document.getElementById('content');
    var marginBottom = 100;
    var bodyWidth = parseInt(document.body.clientWidth, 10);
    var bodyHeight = parseInt(document.body.clientHeight, 10);
    var hudWidth = parseInt(hud.clientWidth, 10);
    var hudHeight = parseInt(hud.clientHeight, 10);
    
    hud.style.left = (bodyWidth - hudWidth) / 2 + 'px';
    hud.style.top = (bodyHeight - hudHeight - marginBottom) + 'px';
}