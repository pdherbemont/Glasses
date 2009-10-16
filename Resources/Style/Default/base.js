/* API - This is the className this file will use. */
var exposed_className = {
    close: "close",
    miniaturize: "miniaturize",
    zoom: "zoom",
    togglePlaying: "toggle-playing",
    enterFullscreen: "enter-fullscreen",
    leaveFullscreen: "leave-fullscreen",
    timeline: "timeline",
    draggable: "draggable",
    dragPlatformWindow: "drag-platform-window",
    dontDragPlatformWindow: "dont-drag-platform-window",
    resizePlatformWindow: "resize-platform-window",
    autohideWhenMouseLeaves: "autohide-when-mouse-leaves",
    dontHideWhenMouseIsInside: "dont-hide-when-mouse-is-inside",
    
    /* These are the 'callback' className */
    hidden: "hidden", /* On autohide-when-mouse-leaves elements */
};

var exposed_Id = {
    content: "content"
};

/* What is being set by the backend and expected here */
var imported_className = {
    playing: "playing"
};


/*
 *  Element additional methods
 */

Element.prototype.hasClassName = function (className)
{
    return this.className.indexOf(className) != -1;
}

Element.prototype.hasClassNameInAncestors = function(className)
{
    if (this.hasClassName(className))
        return true;
    var parent = this.parent;
    if (!parent)
        return false;
    return parent.hasClassNameInAncestors(className);
}

Element.prototype.removeClassName = function(className)
{
    if(!this.hasClassName(className))
        return;
    this.className = this.className.replace(className, "");
}

Element.prototype.addClassName = function (className)
{
    if(this.hasClassName(className))
        return;
    this.className += " " + className;
}

/*
 *  Window Controller
 */
var windowController = new Object();

// Called when page is loaded
windowController.init = function()
{
	// Bind key-equivalent
	document.body.addEventListener('keydown', this.keyDown, false);
	
    // Bind the buttons.
    bindButtonByClassNameToMethod(exposed_className.close, this.close);
    bindButtonByClassNameToMethod(exposed_className.miniaturize, this.miniaturize);
    bindButtonByClassNameToMethod(exposed_className.miniaturize, this.zoom);
    bindButtonByClassNameToMethod(exposed_className.togglePlaying, this.togglePlaying);
    bindButtonByClassNameToMethod(exposed_className.enterFullscreen, this.enterFullscreen);
    bindButtonByClassNameToMethod(exposed_className.leaveFullscreen, this.leaveFullscreen);

    // Deal with HUD hidding.
    var buttons = document.getElementsByClassName(exposed_className.autohideWhenMouseLeaves);
    if (buttons.length > 0) {
        document.body.addEventListener('mousemove', this.revealAutoHiddenElements, false);
        bindByClassNameActionToMethod(exposed_className.dontHideWhenMouseIsInside, 'mouseover', this.interruptAutoHide);        
    }
	
    // Make "draggable" elements draggable.
    var draggableElements = document.getElementsByClassName(exposed_className.draggable);
    for (i = 0; i < draggableElements.length; i++)
        Drag.init(draggableElements[i]);        
	
    // Bind the timeline.
    bindByClassNameActionToMethod(exposed_className.timeline, 'change', this.timelineValueChanged);
    
    // Make sure we'll be able to drag the window.
    bindByClassNameActionToMethod(exposed_className.dragPlatformWindow, 'mousedown', this.mouseDownForWindowDrag);

    // Make sure we'll be able to resize the window.
    bindByClassNameActionToMethod(exposed_className.resizePlatformWindow, 'mousedown', this.mouseDownForWindowResize);
}


// Private method below

// Utility
function bindButtonByClassNameToMethod(className, method)
{			
    bindByClassNameActionToMethod(className, 'click', method);
}

function bindByClassNameActionToMethod(className, action, method)
{
    var buttons = document.getElementsByClassName(className);
    for(var i = 0; i < buttons.length; i++)
        buttons.item(i).addEventListener(action, method, false);
}

windowController.PlatformWindowController = function()
{
    return window.PlatformWindowController;
}

windowController.PlatformWindow = function()
{
    return window.PlatformWindow;
}


windowController.contentHasClassName = function(className)
{
    var content = document.getElementById(exposed_Id.content);
    return content.hasClassName(className) != -1;
}


windowController.removeClassNameFromContent = function(className)
{
    var content = document.getElementById(exposed_Id.content);
    content.removeClassName(className);
}

windowController.addClassNameToContent = function(className)
{
    var content = document.getElementById(exposed_Id.content);
    content.addClassName(className);
}

// JS -> Core

windowController.close = function()
{
    windowController.PlatformWindow().performClose();
}

windowController.miniaturize = function()
{
    windowController.PlatformWindow().miniaturize();
}

windowController.zoom = function()
{
    windowController.PlatformWindow().zoom();
}

windowController.togglePlaying = function()
{
    if(windowController.contentHasClassName(imported_className.playing))
        window.PlatformView.pause();
    else
        window.PlatformView.play();
}

windowController.enterFullscreen = function()
{
    windowController.PlatformWindowController().enterFullscreen();
}

windowController.leaveFullscreen = function()
{
    windowController.PlatformWindowController().leaveFullscreen();
}

windowController.videoResized = function()
{
    window.PlatformView.videoDidResize();
}

windowController.windowResized = function()
{
    windowController.videoResized();
}


windowController.windowFrame = function()
{
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

windowController.saveMouseDownInfo = function(event)
{
    windowController.mouseDownPoint = { x: event.screenX, y: event.screenY };
    windowController.windowFrameAtMouseDown = this.windowFrame();
}

// Timeline

windowController.timelineValueChanged = function()
{
    window.PlatformView.setPosition_(this.value / this.getAttribute('max'));
}

// Window Drag

windowController.mouseDownForWindowDrag = function(event)
{
	// It is reasonnable to only allow click in div, to mouve the window
	// This could probaby be refined
	if (event.srcElement.nodeName != "DIV"
     || event.srcElement.hasClassName(exposed_className.resizePlatformWindow)
     || event.srcElement.hasClassNameInAncestors(exposed_className.dontDragPlatformWindow)) {
        return;
    }
    windowController.saveMouseDownInfo(event);
	document.addEventListener('mouseup', windowController.mouseUpForWindowDrag, false);
	document.addEventListener('mousemove', windowController.mouseDraggedForWindowDrag, false);
}

windowController.mouseUpForWindowDrag = function(event)
{
	document.removeEventListener('mouseup', windowController.mouseUpForWindowDrag, false);
	document.removeEventListener('mousemove', windowController.mouseDraggedForWindowDrag, false);
}

windowController.mouseDraggedForWindowDrag = function(event)
{
	var dx = windowController.mouseDownPoint.x - event.screenX;
	var dy = windowController.mouseDownPoint.y - event.screenY;
	var mouseDownOrigin = windowController.windowFrameAtMouseDown.origin;
	windowController.PlatformWindow().setFrameOrigin__(mouseDownOrigin.x - dx, mouseDownOrigin.y + dy);
}

// Window Resize
windowController.mouseDownForWindowResize = function(event)
{
	// It is reasonnable to only allow click in element that have a resize class
	if (!event.srcElement.hasClassName(exposed_className.resizePlatformWindow))
		return;

    windowController.saveMouseDownInfo(event);

    windowController.PlatformWindow().willStartLiveResize();
        
	document.addEventListener('mouseup', windowController.mouseUpForWindowResize, false);
	document.addEventListener('mousemove', windowController.mouseDraggedForWindowResize, false);
}

windowController.mouseUpForWindowResize = function(event)
{
	document.removeEventListener('mouseup', windowController.mouseUpForWindowResize, false);
	document.removeEventListener('mousemove', windowController.mouseDraggedForWindowResize, false);

    windowController.PlatformWindow().didEndLiveResize();
}

windowController.mouseDraggedForWindowResize = function(event)
{
	var dx = event.screenX - windowController.mouseDownPoint.x;
	var dy = event.screenY - windowController.mouseDownPoint.y;
	var mouseDownOrigin = windowController.windowFrameAtMouseDown.origin;
	var mouseDownSize = windowController.windowFrameAtMouseDown.size;

    var platformWindow = windowController.PlatformWindow();
	platformWindow.setFrame____(mouseDownOrigin.x, mouseDownOrigin.y - dy, mouseDownSize.width + dx, mouseDownSize.height + dy);
    windowController.windowResized();
}

// HUD autohidding
windowController.timer = null;
windowController.autohiddingTime = 0.5;

windowController.autoHideElements = function(event)
{
    window.PlatformView.hideCursorUntilMouseMoves();
    windowController.addClassNameToContent(exposed_className.hidden);
}

// We have a dummy mouseMove events that triggers "revealAutoHiddenElementsAndHideAfter"
// that gets sent anyway. This makes the HUD show up when the HUD is put on screen.
// This is not what we want so skip it.
var globalIsFirstMouseMove = true;

windowController.revealAutoHiddenElementsAndHideAfter = function(seconds, element)
{
    if (globalIsFirstMouseMove) {
        globalIsFirstMouseMove = false;
        return;
    }

    windowController.removeClassNameFromContent(exposed_className.hidden);
    var timer = windowController.timer;
    if (timer)
        clearTimeout(timer);
    if (element && element.hasClassNameInAncestors(exposed_className.exposed_className))
        return;
    windowController.timer = setTimeout(windowController.autoHideElements, seconds * 1000);    
}

windowController.revealAutoHiddenElements = function(event)
{
    windowController.revealAutoHiddenElementsAndHideAfter(windowController.autohiddingTime, event.srcElement);
}

windowController.interruptAutoHide = function(event)
{
    var timer = windowController.timer;
    if (!timer)
        return;
    clearTimeout(timer);
    timer = null;
}

// Key events

windowController.keyDown = function(event)
{
    var key = event.keyCode;

    // Space" key
    if (key == 0x20) 
        windowController.togglePlaying();
}
