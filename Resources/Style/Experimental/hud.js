var HUDController = new Object();
console.log("Hello");
HUDController.init = function() {
    resetHudPosition();	
}

function resetHudPosition() {
    var hud = document.getElementById('draggable-controls');
    var marginBottom = 100;
    var bodyWidth = parseInt(document.body.clientWidth);
    var bodyHeight = parseInt(document.body.clientHeight);
    var hudWidth = parseInt(hud.clientWidth);
    var hudHeight = parseInt(hud.clientHeight);
    
    hud.style.left = (bodyWidth - hudWidth) / 2 + 'px';
    hud.style.top = (bodyHeight - hudHeight - marginBottom) + 'px';
}