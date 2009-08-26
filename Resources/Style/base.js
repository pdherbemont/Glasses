/* API - This is the className this file will use. */
var exposed_className = {
    close: "close",
    miniaturize: "miniaturize",
    zoom: "zoom",
    togglePlaying: "toggle-playing",
    enterFullscreen: "enter-fullscreen",
    leaveFullscreen: "leave-fullscreen",
    timeline: "timeline",
    dragPlatformWindow: "drag-platform-window",
    resizePlatformWindow: "resize-platform-window",
};

var exposed_Id = {
    content: "content"
};

/* What is being set by the backend and expected here */
var imported_className = {
    playing: "playing"
};

/*
 *  Window Controller
 */
var windowController = new Object();

// Called when page is loaded
windowController.init = function() {
    document.body.onresize = windowController.bodyResized;

    // Bind the buttons.
    bindButtonByClassNameToMethod(exposed_className.close, this.close);
    bindButtonByClassNameToMethod(exposed_className.miniaturize, this.miniaturize);
    bindButtonByClassNameToMethod(exposed_className.miniaturize, this.zoom);
    bindButtonByClassNameToMethod(exposed_className.togglePlaying, this.togglePlaying);
    bindButtonByClassNameToMethod(exposed_className.enterFullscreen, this.enterFullscreen);
    bindButtonByClassNameToMethod(exposed_className.leaveFullscreen, this.leaveFullscreen);

    // Bind the timeline.
    bindByClassNameActionToMethod(exposed_className.timeline, 'change', this.timelineValueChanged);
    
    // Make sure we'll be able to drag the window.
    bindByClassNameActionToMethod(exposed_className.dragPlatformWindow, 'mousedown', this.mouseDownForWindowDrag);

    // Make sure we'll be able to resize the window.
    bindByClassNameActionToMethod(exposed_className.resizePlatformWindow, 'mousedown', this.mouseDownForWindowResize);
}


// Private method below

// Utility
function bindButtonByClassNameToMethod(className, method) {
    bindByClassNameActionToMethod(className, 'click', method);
}

function bindByClassNameActionToMethod(className, action, method) {
    var buttons = document.getElementsByClassName(className);
    for(var i = 0; i < buttons.length; i++)
        buttons.item(i).addEventListener(action, method, false);
}


windowController.PlatformWindowController = function() {
    return window.PlatformWindowController;
}

windowController.PlatformWindow = function() {
    return window.PlatformWindow;
}

windowController.contentHasClassName = function(className) {
    var content = document.getElementById(exposed_Id.content);
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
    if(windowController.contentHasClassName(imported_className.playing))
        window.PlatformView.pause();
    else
        window.PlatformView.play();
}

windowController.enterFullscreen = function() {
    windowController.PlatformWindowController().enterFullscreen();
}

windowController.leaveFullscreen = function() {
    windowController.PlatformWindowController().leaveFullscreen();
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
	if (event.srcElement.nodeName != "DIV" || event.srcElement.className.indexOf(exposed_className.resizePlatformWindow) != -1)
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
	if (event.srcElement.className.indexOf(exposed_className.resizePlatformWindow) == -1)
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

