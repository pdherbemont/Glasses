/**
 * A list of MediaView
 * @constructor
 * @implements {KVCArrayObserver}
 * @param {CocoaObject=} cocoaObject
 * @param {Node=} element
 */
var MediaListView = function(cocoaObject, element)
{
    /**
     * @type {CocoaObject|undefined}
     */        
    this.cocoaObject = cocoaObject;

    /**
     * @type {Node}
     */            
    this.element = element || document.createElement("div");

    this.name = "No Name";

    /**
     * @type {Element}
     */    
    this.subviewsElement = document.createElement("ul");

    /**
     * The parent navigation controller if applicable
     * @type {NavigationController}
     */    
    this.navigationController = null;

    /**
     * The subitems
     * @type {Array.<MediaView>}
     */
    this.subviews = new Array();

    /**
     * The selected items
     * @type {Array.<MediaView>}
     */    
    this.selection = new Array();

    this.displayName = "MediaListView";
}

MediaListView.prototype = {
    /**
     * Show the header with name and back button
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
            case Lunettes.EventKey.UpArrow:
                this.selectPrevious();
                this.scrollToSelection();
                return true;
            case Lunettes.EventKey.DownArrow:
                this.selectNext();
                this.scrollToSelection();
                return true;
            case Lunettes.EventKey.Enter:
            case Lunettes.EventKey.RightArrow:
                this.selection[0].action();
                return true;
            case Lunettes.EventKey.Escape:
            case Lunettes.EventKey.LeftArrow:
                if (!this.navigationController.hasElementToPop())
                    return false;
                this.navigationController.pop();
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
    

    /**
     * Nav headers' back button clicked.
     * @param {Event} event
     */
    backClicked: function(event)
    {
        this.navigationcontroller.pop();
    },

    scrollToSelection: function()
    {
        if (this.navigationController.elementStyleUsesScrollBar)
            this.scrollToSelectionForScrollBar();
        else
            this.scrollToSelectionForNonScrollBar();
    },
    /**
     * Expects the container div to have a scroll bar.
     */     
    scrollToSelectionForScrollBar: function()
    {
        var selectionElement = this.selection[0].element;
        var top = selectionElement.offsetTop;
        var height = selectionElement.clientHeight;
        var containerTop = this.element.scrollTop;
        var containerHeight = this.element.clientHeight;

        if (containerTop < top && containerHeight + containerTop < top + height)
            this.element.scrollTop = top + height - containerHeight;
        else if (containerTop > top)
            this.element.scrollTop = top;
        if (this.element.scrollTop < 0 || this.element.scrollTop < height)
            this.element.scrollTop = 0;
    },

    scrollToSelectionForNonScrollBar: function()
    {
        var selectionElement = this.selection[0].element;
        var top = selectionElement.offsetTop;
        var height = selectionElement.clientHeight;

        var containerHeight = 342; //this.element.clientHeight;
        
        this.subviewsElement.style.top = -top + containerHeight/2 + height/2 + "px";
    },
    
    /**
     * Unselect selected elements
     */    
    unselectAll: function()
    {
        for (var i = 0; i < this.selection.length; i++)
            this.selection[i].element.removeClassName("selected");

        this.selection = new Array;
    },

    /**
     * Select previous element
     */        
    selectPrevious: function()
    {
        var index = this.subviews.length - 1;
        if (this.selection.length > 0)
            index = this.subviews.indexOf(this.selection[0]) - 1;

        if (index < 0 || index >= this.subviews.length) {
            //beep();
            console.log("too down");
            return;
        }
        console.log("selecting " + index);

        this.select(this.subviews[index]);
    },

    /**
     * Select next element
     */            
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

    /**
     * Select specified element
     * 
     */                
    select: function(subitem)
    {
        this.unselectAll();
        this.selection.push(subitem);
        subitem.element.addClassName("selected");
    },

    /**
     * Callback from KVC Cocoa bindings.
     */                    
    createCocoaObject: function()
    {
        return new CocoaObject();
    },

    /**
     * Callback from KVC Cocoa bindings
     * @param {CocoaObject} cocoaObject
     * @param {number} index
     */                
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

    /**
     * Callback from KVC Cocoa bindings
     * @param {number} index
     */                    
    removeCocoaObjectAtIndex: function(index)
    {
        console.log("removeCocoaObjectAtIndex " + index);

        if (this.isAttached)
            this.subviews[index].detach();

        this.subviews.splice(index, 1); // Remove the element
    },
    
    /**
     * Callback from KVC Cocoa bindings
     */                        
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