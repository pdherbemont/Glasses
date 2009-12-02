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
    hidden: "hidden" /* On autohide-when-mouse-leaves elements */
};

var exposed_Id = {
    content: "content"
};

/* What is being set by the backend and expected here */
var imported_className = {
    playing: "playing"
};

/*
 * Forward declaration of WebKit's console.
 */
var console;

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

Element.prototype.isAttached = function ()
{
    return this.parentNode;
}
                            
Element.prototype.detach = function ()
{
    window.console.assert(this.parentNode)
    this.parentNode.removeChild(this);
}


Element.prototype.bindKey = function (property, toKeyPath)
{
    window.PlatformView.bindPropertyTo(this, property, toKeyPath);
}

/**
 * An object that can observe a cocoa array object.
 * @constructor
 */
var CocoaObject = function() {};


/**
 * @param {string} keyPath
 * @param {Object} object
 * @param {string} property
 */    
CocoaObject.prototype.bindToObjectProperty = function (keyPath, object, property)
{
    window.console.assert(this.backendObject);
    window.PlatformView.bindDOMObjectToCocoaObject(object, property, this, keyPath);
}

/**
 * @param {Object} object
 * @param {string} property
 */    
CocoaObject.prototype.unbindOfObjectProperty = function (object, property)
{
    window.console.assert(this.backendObject);
    window.PlatformView.unbindDOMObject(object, property);
}


/**
 * An object that can observe a cocoa array object.
 * @interface
 */
function KVCArrayObserver() {};
/**
 * @param {CocoaObject} cocoaObject to observe
 * @param {number} index
 */    
KVCArrayObserver.prototype.insertCocoaObject = function(cocoaObject, index) {};

/**
 * @param {CocoaObject} cocoaObject to observe
 */    
KVCArrayObserver.prototype.removeCocoaObjectAtIndex = function(cocoaObject) {};

/**
 * Remove all
 */
KVCArrayObserver.prototype.removeAllInsertedCocoaObjects = function() {};


/**
 * @param {Object} observer
 * @param {string} keyPath to observe
 */
CocoaObject.prototype.addObserver = function (observer, keyPath)
{
    window.console.assert(observer);
 
    window.PlatformView.addObserverForCocoaObjectWithKeyPath(observer, this, keyPath);
}

/**
 * @param {Object} observer
 * @param {string} keyPath to observe
 */
CocoaObject.prototype.removeObserver = function (observer, keyPath)
{
    window.console.assert(observer);
    window.PlatformView.unobserve(observer, this, keyPath);
}


/*
 *  Window Controller
 */

/**
 * Get the last element of an array
 * @param {Array} array
 */
function last(array)
{
    return array[array.length - 1];
}

Function.prototype.bind = function(thisObject)
{
    var func = this;
    var args = Array.prototype.slice.call(arguments, 1);
    return function() { return func.apply(thisObject, args.concat(Array.prototype.slice.call(arguments, 0))) };
}

/**
 * @constructor
 */

var NavigationController = function()
{
    this.element = document.createElement("div");
    this.items = new Array();
}

NavigationController.prototype = {
    attach: function(parentElement)
    {
        this.visible = true;
        parentElement.appendChild(this.element);
    },
    get currentView()
    {
        return last(this.items);
    },
    push: function(item)
    {
        var current = item;
        var previous = window.last(this.items);

        this.items.push(item);
    
        item.navigationcontroller = this;

        
        // New container start at the right
        item.element.removeClassName("current");
        item.element.removeClassName("left");
        item.element.addClassName("right");

        // Attach the item to that container
        if (item.isAttached)
            item.cancelPendingDetach();
        else
            item.attach(this.element);            

        window.setTimeout(function(){
            // Move the new container to the center
            item.element.addClassName("current");
            item.element.removeClassName("right");
            item.element.removeClassName("left");

            // while previous container moves to the left
            if (previous) {
                previous.element.removeClassName("right");
                previous.element.removeClassName("current");
                previous.element.addClassName("left");
            }
        }, 0);        
    },
    hasElementToPop: function()
    {
        return this.items.length > 1;
    },
    pop: function()
    {
        console.assert(this.hasElementToPop());
        if (!this.hasElementToPop())
            return;
        
        var item = this.items.pop();
        var current = window.last(this.items);

        item.element.addClassName("right");
        item.element.removeClassName("current");
        item.element.removeClassName("left");

        current.element.addClassName("current");
        current.element.removeClassName("left");
        current.element.removeClassName("right");

        // Get rid of that item in the DOM after animation has occured
        item.detachAfterDelay(1000);
    }
}

/**
 * A list of ListView
 * @constructor
 * @param {Node=} element
 */
var ListView = function(element)
{
    
}

/**
 * A list of MediaView
 * @constructor
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var MediaView = function(cocoaObject, parent, elementTag)
{
    this.parent = parent;

    this.element = document.createElement(elementTag);
    this.element.className = "item";

    this.cocoaObject = cocoaObject;

    this.nameElement = document.createElement("div");
    this.nameElement.className = "name";

    this.revealSubitemsElement = document.createElement("div");
    this.revealSubitemsElement.className = "reveal-subitems hidden";
    this.revealSubitemsElement.innerText = ">";

    this.isAttached = false;

    this._subitemsCount = 0;
    this.subitemsCount = 0;

    this.displayName = "MediaView";
}

MediaView.prototype = {
    /**
     * @param {Node=} parentElement
     */            
    attach: function(parentElement)
    {
        console.assert(!this.isAttached, "shouldn't be attached", console.trace());
        
        console.log("MediaView.attach()...");

        this.cocoaObject.bindToObjectProperty("metaDictionary.title", this.nameElement, "innerText");

        console.log("... MediaView.attach() " + this.nameElement.innerText + this);

        this.cocoaObject.bindToObjectProperty("subitems.media.@count", this, "subitemsCount");

        this.element.appendChild(this.nameElement);
        this.element.appendChild(this.revealSubitemsElement);
        
        parentElement.appendChild(this.element);

        this.element.addEventListener('click', this.mouseClicked.bind(this), false);
        this.element.addEventListener('dblclick', this.mouseDoubleClicked.bind(this), false);

        this.isAttached = true;
    },
    detach: function()
    {
        console.log("MediaView.detach() " + this.nameElement.innerText);
        
        this.cocoaObject.unbindOfObjectProperty(this.nameElement, "innerText");
        this.cocoaObject.unbindOfObjectProperty(this, "subitemsCount");
        
        this.element.detach();
        this.isAttached = false;
    },
    
    _subitemsCount: 0,
    set subitemsCount(count){
        
        // Make sure if count is undef (which might be the case, especially
        // if one in the object of the binding is nil.
        // Default it to 0 instead of undefined.
        if (!count)
            count = 0;

        if (count > 0)
            this.revealSubitemsElement.removeClassName("hidden");
        else
            this.revealSubitemsElement.addClassName("hidden");
        this._subitemsCount = count;
        return 0;
    },
    get subitemsCount(){
        return this._subitemsCount;
    },
    mouseClicked: function(event)
    {
        if (!this.parent)
            return;
        
        this.parent.select(this);
        event.stopPropagation();
    },
    action: function()
    {
        if (this.subitemsCount > 0) {
            var listView = new MediaListView(this.cocoaObject);
            listView.showNavigationHeader = true;
            window.windowController.navigationController.push(listView);
        }
        else
            window.PlatformView.playCocoaObject(this.cocoaObject);        
    },
    mouseDoubleClicked: function(event)
    {
        this.action();
    }
    
}


function Global(){};
/**
 * Keys.
 * @enum {number}
 */
Global.EventKey = {
DownArrow: 40,
RightArrow: 39,
UpArrow: 38,
LeftArrow: 37,
Enter: 13,
Escape: 0
};


/**
 * A list of MediaView
 * @constructor
 * @implements {KVCArrayObserver}
 * @param {Node=} element
 */
var MediaListView = function(cocoaObject, element)
{
    this.cocoaObject = cocoaObject;
    this.element = element || document.createElement("div");

    this.name = "No Name";

    this.subviewsElement = document.createElement("ul");

    this.parent = null;

    this.subviews = new Array();

    this.selection = new Array();

    this.displayName = "MediaListView";
}

MediaListView.prototype = {
    /**
     * @type {boolean}
     */    
    _showNavigationHeader: false,
    set showNavigationHeader(show)
    {
        if (this._showNavigationHeader == show)
            return;
        this._showNavigationHeader = show;
        if (show) {
            this.navigationHeaderElement = document.createElement("div");
            this.navigationHeaderElement.className = "header";
            
            this.nameElement = document.createElement("div");
            this.nameElement.className = "name";
            
            this.backButtonElement = document.createElement("button");
            this.backButtonElement.innerText = "Back";
            this.backButtonElement.className = "back";
        }
        else {
            this.navigationHeaderElement.detach();
            this.navigationHeaderElement = null;
            this.nameElement = null;
            this.backButtonElement = null;
        }
    },
    get showNavigationHeader()
    {
        return this._showNavigationHeader;
    },

    /**
     * @param {Event} event
     * @return {boolean} handled
     */    
    
    keyDown: function(event)
    {
        switch (event.keyCode) {
            case Global.EventKey.UpArrow:
                this.selectPrevious();
                return true;
            case Global.EventKey.DownArrow:
                this.selectNext();
                return true;
            case Global.EventKey.Enter:
            case Global.EventKey.RightArrow:
                this.selection[0].action();
                return true;
            case Global.EventKey.Escape:
            case Global.EventKey.LeftArrow:
                if (!this.navigationcontroller.hasElementToPop())
                    return false;
                this.navigationcontroller.pop();
                return true;
        }
        return false;
    },

    /**
     * @type {boolean}
     */    
    isAttached: false,

    /**
     * @param {Node=} parentElement
     */        
    attach: function(parentElement)
    {
        console.assert(!this.isAttached, "shouldn't be attached");

        if (this.detachTimer) {
            window.clearTimeout(this.detachTimer);
            this.detachTimer = null;
        }
        

        if (this.showNavigationHeader && this.cocoaObject) {
            this.cocoaObject.bindToObjectProperty("metaDictionary.title", this.nameElement, "innerText");
            this.backButtonElement.addEventListener('click', this.backClicked.bind(this), false);
            
            this.element.appendChild(this.navigationHeaderElement);
            this.navigationHeaderElement.appendChild(this.backButtonElement);
            this.navigationHeaderElement.appendChild(this.nameElement);
        }

        this.element.appendChild(this.subviewsElement);

        for (var i = 0; i < this.subviews.length; i++) {
            this.subviews[i].attach(this.subviewsElement);
        }
    
        console.log("attach MediaListView " + this.name);
        parentElement.appendChild(this.element);

        this.isAttached = true;

        this.observe();
    },
    detach: function()
    {
        if (this.detachTimer) {
            window.clearTimeout(this.detachTimer);
            this.detachTimer = null;
        }

        console.log("detach MediaListView " + this.name);

        for (var i = 0; i < this.subviews.length; i++)
            this.subviews[i].detach();
        
        this.element.detach();

        this.isAttached = false;
    },
    detachTimer: null,
    detachAfterDelay: function(delay)
    {
        this.detach();
        return;
        var item = this;
        if (this.detachTimer) 
            window.clearTimeout(this.detachTimer);
        this.detachTimer = window.setTimeout(function () { item.detachTimer = null; item.detach(); }, delay);
    },
    cancelPendingDetach: function()
    {
        if (this.detachTimer) 
            window.clearTimeout(this.detachTimer);
        this.detachTimer = null;
    },
    

    backClicked: function(event)
    {
        this.navigationcontroller.pop();
    },
    
    unselectAll: function()
    {
        for (var i = 0; i < this.selection.length; i++)
            this.selection[i].element.removeClassName("selected");

        this.selection = new Array;
    },
    selectPrevious: function()
    {
        var index = this.subviews.length - 1;
        if (this.selection.length > 0)
            index = this.subviews.indexOf(this.selection[0]) - 1;

        if (index < 0 || index >= this.subviews.length) {
            //beep();
            return;
        }
        this.select(this.subviews[index]);
    },
    selectNext: function()
    {
        var index = 0;
        if (this.selection.length > 0)
            index = this.subviews.indexOf(this.selection[0]) + 1;
            
        if (index >= this.subviews.length) {
            //beep();
            return;
        }
        this.select(this.subviews[index]);
    },
    
    select: function(subitem)
    {
        this.unselectAll();
        this.selection.push(subitem);
        subitem.element.addClassName("selected");
    },
    createCocoaObject: function()
    {
        return new CocoaObject();
    },

    insertCocoaObject: function(cocoaObject, index)
    {
        console.log("insertCocoaObject "+ this.isAttached);

            
        var mediaView = new MediaView(cocoaObject, this, "li");
        this.subviews.push(mediaView);

        if (this.isAttached)
            mediaView.attach(this.subviewsElement);

        if (this.selection.length == 0)
            this.select(mediaView);

        return cocoaObject;
    },
    removeCocoaObjectAtIndex: function(index)
    {
        console.log("removeCocoaObjectAtIndex " + index);

        if (this.isAttached)
            this.subviews[index].detach();

        this.subviews.splice(index, 1); // Remove the element
    },
    removeAllInsertedCocoaObjects: function()
    {
        console.log("removeAllInsertedCocoaObjects");

        if (this.isAttached) {
            for (var i = 0; i < this.subviews.length; i++)
                this.subviews[i].detach();
        }
        this.subviews = new Array();
    },
    observe: function()
    {
        if (this.cocoaObject)
            this.cocoaObject.addObserver(this, "subitems.media");
        else
        {
            // FIXME: Better abstraction?
            console.log("observing root media list");
            window.PlatformView.addObserverForCocoaObjectWithKeyPath(this, null, "rootMediaList.media");
        }
    }
}

// Called when page is loaded

/**
 * @constructor
 */
var WindowController = function ()
{
}



WindowController.prototype = {
    init: function()
    {
        // Bind key-equivalent
        document.body.addEventListener('keydown', this.keyDown, false);
        
        // Bind the buttons.
        bindButtonByClassNameToMethod(exposed_className.close, this.close);
        bindButtonByClassNameToMethod(exposed_className.miniaturize, this.miniaturize);
        bindButtonByClassNameToMethod(exposed_className.zoom, this.zoom);
        bindButtonByClassNameToMethod(exposed_className.togglePlaying, this.togglePlaying);
        bindButtonByClassNameToMethod(exposed_className.enterFullscreen, this.enterFullscreen);
        bindButtonByClassNameToMethod(exposed_className.leaveFullscreen, this.leaveFullscreen);
        
        // Deal with HUD hidding.
        var buttons = document.getElementsByClassName(exposed_className.autohideWhenMouseLeaves);
        if (buttons.length > 0) {
            document.body.addEventListener('mousemove', this.revealAutoHiddenElements.bind(this), false);
            bindByClassNameActionToMethod(exposed_className.dontHideWhenMouseIsInside, 'mouseover', this.interruptAutoHide.bind(this));        
        }
        
        // Make "draggable" elements draggable.
        var draggableElements = document.getElementsByClassName(exposed_className.draggable);
        for (var i = 0; i < draggableElements.length; i++)
            window.Drag.init(draggableElements[i]);        
        
        var elements = document.getElementsByClassName("ellapsed-time");
        for (i = 0; i < elements.length; i++)
            elements[i].bindKey("innerText", "mediaPlayer.time.stringValue");
        
        var mediaList = document.getElementById("mediaList");
        if (mediaList) {
            this.rootMediaList = new MediaListView(null);
//            this.rootMediaList.observe = function () {
//                window.PlatformView.observe(null, "rootMediaList.media", this);
//            };
            
            this.navigationController = new NavigationController;
            this.navigationController.attach(mediaList);
            this.navigationController.push(this.rootMediaList);
        }
        
        // Deal with HUD hidding.
        buttons = document.getElementsByClassName(exposed_className.autohideWhenMouseLeaves);
        if (buttons.length > 0) {
            document.body.addEventListener('mousemove', this.revealAutoHiddenElements.bind(this), false);
            bindByClassNameActionToMethod(exposed_className.dontHideWhenMouseIsInside, 'mouseover', this.interruptAutoHide.bind(this));        
        }
		
        // Bind the timeline.
        bindByClassNameActionToMethod(exposed_className.timeline, 'change', this.timelineValueChanged.bind(this));
        
        // Make sure we'll be able to drag the window.
        bindByClassNameActionToMethod(exposed_className.dragPlatformWindow, 'mousedown', this.mouseDownForWindowDrag.bind(this));
        
        // Make sure we'll be able to resize the window.
        bindByClassNameActionToMethod(exposed_className.resizePlatformWindow, 'mousedown', this.mouseDownForWindowResize.bind(this));        
    },
    PlatformWindowController: function()
    {
        return window.PlatformWindowController;
    },
    
    PlatformWindow: function()
    {
        return window.PlatformWindow;
    },
    
    
    contentHasClassName: function(className)
    {
        var content = document.getElementById(exposed_Id.content);
        return content.hasClassName(className) != -1;
    },
    
    
    removeClassNameFromContent: function(className)
    {
        var content = document.getElementById(exposed_Id.content);
        content.removeClassName(className);
    },
    
    addClassNameToContent: function(className)
    {
        var content = document.getElementById(exposed_Id.content);
        content.addClassName(className);
    },
    
    // JS -> Core
    
    close: function()
    {
        this.PlatformWindow().performClose();
    },
    
    miniaturize: function()
    {
        this.PlatformWindow().miniaturize();
    },
    
    zoom: function()
    {
        this.PlatformWindow().zoom();
    },
    
    togglePlaying: function()
    {
        if(this.contentHasClassName(imported_className.playing))
            window.PlatformView.pause();
        else
            window.PlatformView.play();
    },
    
    enterFullscreen: function()
    {
        this.PlatformWindowController().enterFullscreen();
    },
    
    leaveFullscreen: function()
    {
        this.PlatformWindowController().leaveFullscreen();
    },
    
    videoResized: function()
    {
        window.PlatformView.videoDidResize();
    },
    
    windowResized: function()
    {
        this.videoResized();
        
    },
    
    
    windowFrame: function()
    {
        var platformWindow = this.PlatformWindow();
        var origin = { x: platformWindow.frameOriginX(), y: platformWindow.frameOriginY() };
        var size = { height: platformWindow.frameSizeHeight(), width: platformWindow.frameSizeWidth() };
        return { origin: origin, size: size };
    },
    
    // ------------------------------------------
    // Event handlers
    
    // Common
    
    mouseDownPoint: null,
    windowFrameAtMouseDown: null,
    
    saveMouseDownInfo: function(event)
    {
        this.mouseDownPoint = { x: event.screenX, y: event.screenY };
        this.windowFrameAtMouseDown = this.windowFrame();
    },
    
    // Timeline
    
    timelineValueChanged: function()
    {
        window.PlatformView.setPosition_(this.value / this.getAttribute('max'));
    },
    
    // Window Drag
    
    mouseDownForWindowDrag: function(event)
    {
        // It is reasonnable to only allow click in div, to mouve the window
        // This could probaby be refined
        if (event.srcElement.nodeName != "DIV"
            || event.srcElement.hasClassName(exposed_className.resizePlatformWindow)
            || event.srcElement.hasClassNameInAncestors(exposed_className.dontDragPlatformWindow)) {
            return;
        }
        this.saveMouseDownInfo(event);
        this._mouseUpListener = this.mouseUpForWindowDrag.bind(this);
        this._mouseDragListener = this.mouseUpForWindowDrag.bind(this);
        document.addEventListener('mouseup', this._mouseUpListener, false);
        document.addEventListener('mousemove', this._mouseDragListener, false);
    },
    
    mouseUpForWindowDrag: function(event)
    {
        document.removeEventListener('mouseup', this._mouseUpListener, false);
        document.removeEventListener('mousemove', this._mouseDragListener, false);
    },
    
    mouseDraggedForWindowDrag: function(event)
    {
        var dx = this.mouseDownPoint.x - event.screenX;
        var dy = this.mouseDownPoint.y - event.screenY;
        var mouseDownOrigin = this.windowFrameAtMouseDown.origin;
        this.PlatformWindow().setFrameOrigin__(mouseDownOrigin.x - dx, mouseDownOrigin.y + dy);
    },
    
    // Window Resize
    mouseDownForWindowResize: function(event)
    {
        // It is reasonnable to only allow click in element that have a resize class
        if (!event.srcElement.hasClassName(exposed_className.resizePlatformWindow))
            return;
        
        this.saveMouseDownInfo(event);
        
        this.PlatformWindow().willStartLiveResize();
        
        document.addEventListener('mouseup', this.mouseUpForWindowResize.bind(this), false);
        document.addEventListener('mousemove', this.mouseDraggedForWindowResize.bind(this), false);
    },
    
    mouseUpForWindowResize: function(event)
    {
        document.removeEventListener('mouseup', this.mouseUpForWindowResize.bind(this), false);
        document.removeEventListener('mousemove', this.mouseDraggedForWindowResize.bind(this), false);
        
        this.PlatformWindow().didEndLiveResize();
    },
    
    mouseDraggedForWindowResize: function(event)
    {
        var dx = event.screenX - this.mouseDownPoint.x;
        var dy = event.screenY - this.mouseDownPoint.y;
        var mouseDownOrigin = this.windowFrameAtMouseDown.origin;
        var mouseDownSize = this.windowFrameAtMouseDown.size;
        
        var platformWindow = this.PlatformWindow();
        platformWindow.setFrame____(mouseDownOrigin.x, mouseDownOrigin.y - dy, mouseDownSize.width + dx, mouseDownSize.height + dy);
        this.windowResized();
    },
    
    // HUD autohidding
    timer: null,
    autohiddingTime: 0.5,

    autoHideElements: function(event)
    {
        window.PlatformView.hideCursorUntilMouseMoves();
        this.addClassNameToContent(exposed_className.hidden);
    },
    
    // We have a dummy mouseMove events that triggers "revealAutoHiddenElementsAndHideAfter"
    // that gets sent anyway. This makes the HUD show up when the HUD is put on screen.
    // This is not what we want so skip it.
    globalIsFirstMouseMove: true,
    
    revealAutoHiddenElementsAndHideAfter: function(seconds, element)
    {
        if (this.globalIsFirstMouseMove) {
            this.globalIsFirstMouseMove = false;
            return;
        }
        
        this.removeClassNameFromContent(exposed_className.hidden);
        var timer = this.timer;
        if (timer)
            window.clearTimeout(timer);
        if (element && element.hasClassNameInAncestors(exposed_className.dontHideWhenMouseIsInside))
            return;
        this.timer = window.setTimeout(this.autoHideElements.bind(this), seconds * 1000);    
    },
    
    revealAutoHiddenElements: function(event)
    {
        this.revealAutoHiddenElementsAndHideAfter(this.autohiddingTime, event.srcElement);
    },
    
    interruptAutoHide: function(event)
    {
        var timer = this.timer;
        if (!timer)
            return;
        window.clearTimeout(timer);
        timer = null;
    },
    
    // Key events
    
    keyDown: function(event)
    {
        var key = event.keyCode;
        
        // Space" key
        if (key == 0x20) 
            this.togglePlaying();
    }
    
}

window.windowController = new WindowController;


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

