/*
 *  Window Controller
 */
var windowController = new Object();

// Called when page is loaded
windowController.init = function() {
    // Bind the buttons.
    bindButtonByIdToMethod("close", this.close);
    bindButtonByIdToMethod("miniaturize", this.miniaturize);
    bindButtonByIdToMethod("zoom", this.zoom);
    bindButtonByIdToMethod("toggle-playing", this.togglePlaying);
    bindButtonByIdToMethod("fullscreen", this.enterFullscreen);

    // Bind the timeline.
    var timeline = document.getElementById("timeline");
    timeline.addEventListener('change', this.timelineValueChanged, false);
    
    // Make sure we'll be able to drag the window.
    var content = document.getElementById("content");
    content.addEventListener('mousedown', this.mouseDownForWindowDrag, false);

    // Make sure we'll be able to resize the window.
    var resize = document.getElementById("resize");
    resize.addEventListener('mousedown', this.mouseDownForWindowResize, true);
}


// Private method below

// Utility
function bindButtonByIdToMethod(id, method) {
    var button = document.getElementById(id);
    button.onclick = method;
}

windowController.PlatformWindowController = function() {
    return window.PlatformWindowController;
}

windowController.PlatformWindow = function() {
    return window.PlatformWindow;
}

windowController.contentHasClassName = function(className) {
    var content = document.getElementById("content");
    return content.className.indexOf(className) != -1;
}

windowController.close = function() {
    windowController.PlatformWindow().performClose();
}

windowController.miniaturize = function() {
    windowController.PlatformWindow().miniaturize();
}

windowController.zoom = function() {
    windowController.PlatformWindow().zoom();
}

windowController.togglePlaying = function() {
    if(windowController.contentHasClassName("playing"))
        window.PlatformView.pause();
    else
        window.PlatformView.play();
}

windowController.enterFullscreen = function() {
    windowController.PlatformWindowController().enterFullscreen();
}

windowController.videoResized = function() {
    window.PlatformView.videoDidResize();
}

windowController.bodyResized = function() {
    // Hack for now
    windowController.videoResized();
}


windowController.windowFrame = function() {
    var platformWindow = windowController.PlatformWindow();
    var origin = { x: platformWindow.frameOriginX(), y: platformWindow.frameOriginY() };
    var size = { height: platformWindow.frameSizeHeight(), width: platformWindow.frameSizeWidth() };
    return { origin: origin, size: size };
}

// ------------------------------------------
// Event handlers

// Common

windowController.mouseDownPoint = null;
windowController.windowFrameAtMouseDown = null;

windowController.saveMouseDownInfo = function(event) {
    windowController.mouseDownPoint = { x: event.screenX, y: event.screenY };
    windowController.windowFrameAtMouseDown = this.windowFrame();
}

// Timeline

windowController.timelineValueChanged = function() {
    window.PlatformView.setPosition_(this.value / this.getAttribute('max'));
}

// Window Drag

windowController.mouseDownForWindowDrag = function(event) {
	// It is reasonnable to only allow click in div, to mouve the window
	// This could probaby be refined
	if (event.srcElement.nodeName != "DIV" || event.srcElement.className.indexOf("resize") != -1)
		return;
    windowController.saveMouseDownInfo(event);
	document.addEventListener('mouseup', windowController.mouseUpForWindowDrag, false);
	document.addEventListener('mousemove', windowController.mouseDraggedForWindowDrag, false);
}

windowController.mouseUpForWindowDrag = function(event) {
	document.removeEventListener('mouseup', windowController.mouseUpForWindowDrag, false);
	document.removeEventListener('mousemove', windowController.mouseDraggedForWindowDrag, false);
}

windowController.mouseDraggedForWindowDrag = function(event) {
	var dx = windowController.mouseDownPoint.x - event.screenX;
	var dy = windowController.mouseDownPoint.y - event.screenY;
	var mouseDownOrigin = windowController.windowFrameAtMouseDown.origin;
	windowController.PlatformWindow().setFrameOrigin__(mouseDownOrigin.x - dx, mouseDownOrigin.y + dy);
}

// Window Resize
windowController.mouseDownForWindowResize = function(event) {
	// It is reasonnable to only allow click in element that have a resize class
	if (event.srcElement.className.indexOf("resize") == -1)
		return;

    windowController.saveMouseDownInfo(event);

    windowController.PlatformWindow().willStartLiveResize();
        
	document.addEventListener('mouseup', windowController.mouseUpForWindowResize, false);
	document.addEventListener('mousemove', windowController.mouseDraggedForWindowResize, false);
}

windowController.mouseUpForWindowResize = function(event) {
	document.removeEventListener('mouseup', windowController.mouseUpForWindowResize, false);
	document.removeEventListener('mousemove', windowController.mouseDraggedForWindowResize, false);

    windowController.PlatformWindow().didEndLiveResize();
}

windowController.mouseDraggedForWindowResize = function(event) {
	var dx = event.screenX - windowController.mouseDownPoint.x;
	var dy = event.screenY - windowController.mouseDownPoint.y;
	var mouseDownOrigin = windowController.windowFrameAtMouseDown.origin;
	var mouseDownSize = windowController.windowFrameAtMouseDown.size;

    var platformWindow = windowController.PlatformWindow();
	platformWindow.setFrame____(mouseDownOrigin.x, mouseDownOrigin.y - dy, mouseDownSize.width + dx, mouseDownSize.height + dy);
}

