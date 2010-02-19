/**
 * A list of ListView
 * @constructor
 * @implements {KVCArrayObserver}
 * @param {CocoaObject} cocoaObject
 * @param {ListItemView} listItemViewClass
 * @param {Node=} element
 */
var ListView = function(cocoaObject, listItemViewClass, element)
{
    this.listItemViewClass = listItemViewClass;

    /**
     * @type {CocoaObject|undefined}
     */
    this.cocoaObject = cocoaObject;

    /**
     * @type {Node}
     */
    this.element = element || document.createElement("div");
    this.element.className = "list-view";
    this.name = "No Name";

    console.log(this.element);

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

ListView.prototype = {
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

        this.element.onscroll = this.didScroll.bind(this);
        window.addEventListener('resize', this.didResize.bind(this), false);

        this.element.addEventListener('dragenter', this.dragEntered.bind(this), false);
        this.element.addEventListener('dragover', this.dragOvered.bind(this), false);
        this.element.addEventListener('dragleave', this.dragDidLeave.bind(this), false);
        this.element.addEventListener('drop', this.dropped.bind(this), false);

        if (this.showNavigationHeader && this.cocoaObject) {
            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "metaDictionary.title");
            this.backButtonElement.addEventListener('click', this.backClicked.bind(this), false);

            this.element.appendChild(this.navigationHeaderElement);
            this.navigationHeaderElement.appendChild(this.backButtonElement);
            this.navigationHeaderElement.appendChild(this.nameElement);
        }

        this.element.appendChild(this.subviewsElement);

        for (var i = 0; i < this.subviews.length; i++) {
            this.subviews[i].attach(this.subviewsElement);
        }

        if (parentElement)
            parentElement.appendChild(this.element);

        this.isAttached = true;

        this.observe();
        this.updateVisibleItems();
    },
    /**
     * Event handler for scroll.
     * {Event} event
     */
didScroll: function(event)
    {
        this.updateVisibleItems();
    },
    /**
     * Event handler for scroll.
     * {Event} event
     */
didResize: function(event)
    {
        this.updateVisibleItems();
    },

indexAtPosition: function(x, y)
    {
        var item = this.subviews[0].element;
        var height = item.offsetHeight;

        var ret = Math.floor(y / height);
        if (ret <= 0)
            ret = 0;
        if (ret > this.subviews.length)
            ret = this.subviews.length;
        return ret;
    },

resetDrag: function()
    {
        for(var i = 0; i < this.subviews.length; i++) {
            if (this.subviews[i].element.style.marginTop != "0px") {
                this.subviews[i].element.style.marginTop = "0px";
                this.subviews[i].element.style.borderTopStyle = "none"; // FIXME- do that in CSS?
            }
        }
    },

highlightDragPosition: function(index)
    {
        for(var i = 0; i < this.subviews.length; i++) {
            var top = this.subviews[i].element.style.marginTop;
            if (index != i) {
                if (top != "0px") {
                    this.subviews[i].element.style.marginTop = "0px";
                    this.subviews[i].element.style.borderTop = "none"; // FIXME- do that in CSS?
                }
            }
            else {
                if (top != "40px") {
                    this.subviews[index].element.style.marginTop = "40px";
                    var style = this.subviews[i].element.style;
                    this.subviews[i].element.style["border-top-style"] = style["border-top-style"]; // FIXME- do that in CSS?
                    this.subviews[i].element.style["border-top-width"] = style["border-top-width"]; // FIXME- do that in CSS?
                    this.subviews[i].element.style["border-top-color"] = style["border-top-color"]; // FIXME- do that in CSS?
                }
            }
        }
    },

    /**
     * {Event} event
     */

dragEntered: function(event)
    {
        // Work around what seems to be a webkit bug.
        if (!this._dragEnteredNumber)
            this._dragEnteredNumber = 0;
        this._dragEnteredNumber++;

        var url = event.dataTransfer.getData("public.file-url");
        if (!url)
            return;

        if (this._dragEnteredNumber >= 1)
            return;

        //        var index = this.indexAtPosition(event.layerX, event.layerY);
        //        this.highlightDragPosition(index);
        //        event.preventDefault();
    },

    /**
     * {Event} event
     */
dragDidLeave: function(event)
    {
        this._dragEnteredNumber--;
        if (this._dragEnteredNumber <= 0)
            this.resetDrag();

        var url = event.dataTransfer.getData("public.file-url");
        if (!url)
            return;
        event.preventDefault();
    },


    /**
     * {Event} event
     */
dragOvered: function(event)
    {
        var url = event.dataTransfer.getData("public.file-url");
        if (!url)
            return;
        var index = this.indexAtPosition(event.x, event.y);
        this.highlightDragPosition(index);
        event.preventDefault();
    },

    /**
     * {Event} event
     */
dropped: function(event)
    {
        var url = event.dataTransfer.getData("public.file-url");
        if (!url)
            return;
        this.resetDrag();
        var media = CocoaObject.createMediaFromURL(url);
        this.arrayController.insertObjectAtIndex(media, this.indexAtPosition(event.x, event.y));
        event.preventDefault();
    },

    /**
     * Make sure the visible items knows
     * they are visible.
     *
     * The visible MediaView will bind their contents
     * from here.
     */
updateVisibleItems: function()
    {
        if (!this.subviews[0])
            return;
        var item = this.subviews[0].element;
        var height = item.offsetHeight;

        var top = 0;
        if (this.navigationController && !this.navigationController.elementStyleUsesScrollBar) {
            top = -parseInt(this.subviewsElement.style.top);
            if (!top)
                top = 0;
        }
        else
            top = this.element.scrollTop;

        if (this.visibleTimer)
            window.clearTimeout(this.visibleTimer);

        if (isNaN(top) || isNaN(height) || !height) {
            this.visibleTimer = window.setTimeout(this.updateVisibleItems.bind(this), 50);
            return;
        }

        var firstVisibleIndex = Math.max(Math.floor(top / height), 0);
        var nVisibleIndexes = Math.floor(this.element.clientHeight / height);
        var count = firstVisibleIndex + nVisibleIndexes + 2;
        if (count > this.subviews.length)
            count = this.subviews.length;

        console.log("There are " + (count - firstVisibleIndex) + " visible");
        for (var i = firstVisibleIndex; i < count; i++)
            this.subviews[i].visible = true;
    },

detach: function()
    {
        if (this.detachTimer) {
            window.clearTimeout(this.detachTimer);
            this.detachTimer = null;
        }

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



scrollToSelection: function()
    {
        if (!this.navigationController || this.navigationController.elementStyleUsesScrollBar)
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

        var containerHeight = this.element.clientHeight;

        this.subviewsElement.style.top = -top + containerHeight/2 + height/2 + "px";
        this.updateVisibleItems();
    },

    /**
     * Unselect selected elements
     */
    _unselectAll: function()
    {
        this.arrayController.setSelectedIndex(-1);

        for (var i = 0; i < this.selection.length; i++)
            this.selection[i].element.removeClassName("selected");

        this.selection = new Array;
    },

    unselectAllBeforeSelection: function()
    {
        this._unselectAll();
    },
    /**
     * Unselect selected elements
     */
    unselectAll: function()
    {
        this._unselectAll();
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
            return;
        }

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
        this.unselectAllBeforeSelection();
        this.selection.push(subitem);
        var index = this.subviews.indexOf(this.selection[0]);
        this.arrayController.setSelectedIndex(index);

        subitem.element.addClassName("selected");
    },

appendCocoaObject: function(cocoaObject, index)
    {
        var mediaView = new this.listItemViewClass(cocoaObject, this, "li");
        this.subviews.push(mediaView);

        if (this.isAttached)
            mediaView.attach(this.subviewsElement);

        if (this.selection.length == 0)
            this.select(mediaView);

        this.updateVisibleItems();
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
        this.appendCocoaObject(cocoaObject);
        this.updateVisibleItems();
    },

    /**
     * Callback from KVC Cocoa bindings
     * @param {number} index
     */
removeCocoaObjectAtIndex: function(index)
    {
        if (this.isAttached)
            this.subviews[index].detach();

        this.subviews.splice(index, 1); // Remove the element

        this.updateVisibleItems();
    },

setCocoaObjects: function(array)
    {
        console.time("setCocoaObjects");

        console.profile("setCocoaObjects");

        var needToReattachSubviewsElement = false;

        this.subviewsElement.parentNode.removeChild(this.subviewsElement);
        if (this.isAttached) {
            for (var i = 0; i < this.subviews.length; i++)
                this.subviews[i].detachWithoutRemoving();
        }
        this.subviews = new Array();

        // Create the new one and add it from here.
        this.subviewsElement = document.createElement("ul");


        console.time("insertCocoaObject");
        for (var i = 0; i < array.length; i++)
            this.appendCocoaObject(array[i]);
        console.timeEnd("insertCocoaObject");

        // We are done, add back the child.
        this.element.appendChild(this.subviewsElement);

        console.time("updateVisibleItems");
        this.updateVisibleItems();
        console.timeEnd("updateVisibleItems");

        console.profileEnd("setCocoaObjects");
        console.timeEnd("setCocoaObjects");

    },

    /**
     * Callback from KVC Cocoa bindings
     */
removeAllInsertedCocoaObjects: function()
    {
        // Instead of removing elements one by one,
        // remove the parent.
        this.subviewsElement.parentNode.removeChild(this.subviewsElement);
        this.subviewsElement = document.createElement("ul");;
        this.element.appendChild(this.subviewsElement);

        if (this.isAttached) {
            for (var i = 0; i < this.subviews.length; i++)
                this.subviews[i].detachWithoutRemoving();
        }
        this.subviews = new Array();

        this.updateVisibleItems();
    },

    /**
     * Callback from KVC Cocoa bindings
     */
_arrayController: null,
    set arrayController(controller)
    {
        if (!controller)
            controller = null;

        Lunettes.willChange(this, "arrayController");
        this._arrayController = controller;
        Lunettes.didChange(this, "arrayController");

        /* Sync selection */
        if (this.selection[0]) {
            var index = this.subviews.indexOf(this.selection[0]) + 1;
            this.arrayController.setSelectedIndex(index);
        }
    },
    get arrayController()
    {
        if (!this._arrayController)
            this._arrayController = null;
        return this._arrayController;
    },
    observe: function()
    {
        console.assert(!this.arrayController);
        if (this.arrayController)
            return;
        console.assert(this.subItemsKeyPath, "No keypath provided");


        var cocoaObject = this.cocoaObject;
        this.arrayController = cocoaObject.createArrayControllerFromKeyPath(this.subItemsKeyPath);

        this.arrayController.addObserver(this, "arrangedObjects");
    }
}
