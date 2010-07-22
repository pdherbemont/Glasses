/**
 * A list of ListView
 * @constructor
 * @implements {KVCArrayObserver}
 * @param {CocoaObject} cocoaObject
 * @param {Object} listItemViewClass
 * @param {string} subItemsKeyPath
 * @param {Node=} element
 * @param {string=} className
 */
var ListView = function(cocoaObject, subItemsKeyPath, listItemViewClass, element, className)
{
    this.listItemViewClass = listItemViewClass;
    this.subItemsKeyPath = subItemsKeyPath;

    /**
     * @type {CocoaObject|undefined}
     */
    this.cocoaObject = cocoaObject;

    /**
     * @type {Node}
     */
    this.element = element || document.createElement("div");

    if (!className)
        className = "list-view";
    this.element.addClassName(className);
    this.name = "No Name";

    /**
     * @type {Element}
     */
    this.subviewsElement = document.createElement("ul");
    this.subviewsElement.className  = "subitems";

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

        this.observe();

        if (this.showNavigationHeader && this.cocoaObject) {
            Lunettes.connect(this.nameElement, "textContent", this.cocoaObject, "metaDictionary.title");
            this.backButtonElement.addEventListener('click', this.backClicked.bind(this), false);

            this.element.appendChild(this.navigationHeaderElement);
            this.navigationHeaderElement.appendChild(this.backButtonElement);
            this.navigationHeaderElement.appendChild(this.nameElement);
        }

        this.element.appendChild(this.subviewsElement);

        for (var i = 0; i < this.subviews.length; i++)
            this.subviews[i].attach(this.subviewsElement);

        if (parentElement)
            parentElement.appendChild(this.element);

        this.isAttached = true;

        this.updateVisibleItems();

        if (this._savedScrollTop)
            this.element.scrollTop = this._savedScrollTop;
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
    _visibleItemHeight: 0,
    _noVisibleItemOptimization: false,
    updateVisibleItems: function()
    {

        // We are doing a bunch of optimization below.
        // Those unfortunately requires a specific CSS layout.
        // Hence we have a flag to disable them all together.
        var noVisibleItemOptimization = this._noVisibleItemOptimization;
        if (noVisibleItemOptimization) {
            for (var i = 0; i < this.subviews.length; i++)
                this.subviews[i].visible = true;
            return;
        }
        if (!this.subviews[0])
            return;
        var height = this._visibleItemHeight;
        var item = this.subviews[0].element;
        if (!item)
            return;

        if (!height) {
            height = item.offsetHeight;
        }

        var top = 0;
        if (this.navigationController && !this.navigationController.elementStyleUsesScrollBar) {
            top = -parseInt(this.subviewsElement.style.top, 10);
            if (!top)
                top = 0;

            // Work around fullscreen hud and css property readiness.
            if (this.visibleTimer)
                window.clearTimeout(this.visibleTimer);

            if (isNaN(top) || isNaN(height) || !height) {
                this.visibleTimer = window.setTimeout(this.updateVisibleItems.bind(this), 100);
                return;
            }
        }
        else
            top = this.element.scrollTop;

        var numberOfRowInSelection = 0;
        var selectionIndex = -1;
        // Specify a custom size for the selection
        var selectionHeight = this._selectionHeight;
        if (selectionHeight > 0) {
            // When the selection height is changing we need to account this.
            if (this.selection.length == 1)
                selectionIndex = this.subviews.indexOf(this.selection[0])
            if (selectionIndex > 0) {
                numberOfRowInSelection = selectionHeight / height;
            }
        }

        var firstVisibleIndex = Math.max(Math.floor(top / height), 0);
        if (firstVisibleIndex > selectionIndex)
            firstVisibleIndex -= Math.round(numberOfRowInSelection);

        var nVisibleIndexes = Math.floor(this.element.clientHeight / height);
        var count = firstVisibleIndex + nVisibleIndexes + 2;
        if (count > this.subviews.length)
            count = this.subviews.length;

        for (var i = firstVisibleIndex; i < count; i++)
            this.subviews[i].visible = true;
    },

    detach: function()
    {
        console.assert(this.isAttached, "Should be attached");

        this._savedScrollTop = this.element.scrollTop;

        if (this.detachTimer) {
            window.clearTimeout(this.detachTimer);
            this.detachTimer = null;
        }

        this.element.detach();

        for (var i = 0; i < this.subviews.length; i++)
            this.subviews[i].detachWithoutRemoving();

        this.arrayController.removeObserver(this, "arrangedObjects");

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
        for (var i = 0; i < this.selection.length; i++) {
            if (this.selection[i])
                this.selection[i].element.removeClassName("selected");
        }
        this.selection = [];
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
        this.addToSelection(subitem);
    },
    updateSelectionIndexes: function()
    {
        var ret = [];
        for (var i = 0; i < this.selection.length; i++)
            ret.push(this.subviews.indexOf(this.selection[i]));
        this.selectionIndexes = ret;
        if (this.selection.length == 1)
            this.element.addClassName("one-selection");
        else
            this.element.removeClassName("one-selection");
    },
    _selectionIndexes: [],
    set selectionIndexes(indexes)
    {
        if (!indexes)
            indexes = [];

        Lunettes.willChange(this, "selectionIndexes");
        this._selectionIndexes = indexes;
        Lunettes.didChange(this, "selectionIndexes");

        this.unselectAllBeforeSelection();
        for (var i = 0; i < indexes.length; i++) {
            var subview = this.subviews[indexes[i]];
            if (!subview)
                continue;
            this.selection.push(subview);
            var element = subview.element;
            if (element)
                element.addClassName("selected");
        }

    },
    get selectionIndexes()
    {
        return this._selectionIndexes;
    },
    addToSelection: function(subitem)
    {
        if (this.doesSelectionContain(subitem))
            return;
        // Insert our item at the right place.
        var selection = this.selection;
        var subviews = this.subviews;
        var index = subviews.indexOf(subitem);
        var min = 0;
        var max = selection.length - 1;
        var middle = min - max / 2;
        while (middle > 0) {
            var middleIndex = subviews.indexOf(selection[middle]);
            if (middleIndex < index)
                min = middleIndex;
            else
                max = middleIndex;
            middle = min - max / 2;
        }
        this.selection.splice(min, 0, subitem);
        this.updateSelectionIndexes();
    },
    doesSelectionContain: function(subitem)
    {
        return this.selection.indexOf(subitem) >= 0;
    },
    removeFromSelection: function(subitem)
    {
        var index = this.selection.indexOf(subitem);
        this.selection.splice(index);
        subitem.element.removeClassName("selected");
        this.updateSelectionIndexes();
    },
    toggleItemSelection: function(subitem)
    {
        if (this.selection.indexOf(subitem) >= 0)
            this.removeFromSelection(subitem);
        else
            this.addToSelection(subitem);
    },

    selectTo: function(subitem)
    {
        var length = this.selection.length;
        if (length == 0) {
            this.select(subitem);
            return;
        }
        var selection = this.selection;
        var minIndex = this.subviews.indexOf(selection[0]);
        var maxIndex = this.subviews.indexOf(selection[length - 1]);
        var thisIndex = this.subviews.indexOf(subitem);

        var startIndex;
        var endIndex;
        if (thisIndex < minIndex) {
            startIndex = thisIndex;
            endIndex = minIndex;
        } else if (thisIndex < maxIndex) {
            startIndex = minIndex;
            endIndex = thisIndex;
        } else {
            startIndex = maxIndex;
            endIndex = thisIndex;
        }

        for (var i = startIndex; i <= endIndex; i++)
            this.addToSelection(this.subviews[i]);
    },

    _shouldAutoSelectInsertedItem: true,
    appendCocoaObject: function(cocoaObject, index)
    {
        var mediaView = new this.listItemViewClass(cocoaObject, this, "li");
        this.subviews.push(mediaView);

        if (this.isAttached)
            mediaView.attach(this.subviewsElement);

        if (this._shouldAutoSelectInsertedItem && this.selection.length == 0)
            this.select(mediaView);

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
     * @param {ListItemView} subview
     */
    removeSubview: function(subview)
    {
        this.removeCocoaObjectAtIndex(this.subviews.indexOf(subview));
    },

    /**
     * Callback from KVC Cocoa bindings
     * @param {number} index
     */
    removeCocoaObjectAtIndex: function(index)
    {
        if (this.isAttached)
            this.subviews[index].detach();

        console.time("setCocoaObjects");

        this.subviews.splice(index, 1); // Remove the element

        this.updateVisibleItems();
    },

    setCocoaObjects: function(array)
    {
        console.profile("setCocoaObjects");

        console.time("setCocoaObjects");

        var needToReattachSubviewsElement = false;

        var oldSubviewsElement = this.subviewsElement;
        var oldSubviews = this.subviews;

        this.subviews = [];

        // The following is to optimize a setting of the same array.
        // Create a dictionary that associate the media uid -> object
        // Mark it has toBeTrashed by default.
        var dict = { };
        for (var i = 0; i < oldSubviews.length; i++) {
            dict[oldSubviews[i].cocoaObject.uid] = oldSubviews[i];
            oldSubviews[i].toBeTrashed = true;
        }

        // Create the new one and add it from here.
        this.subviewsElement = oldSubviewsElement.cloneNode(false);

        var conserved = 0;
        for (var i = 0; i < array.length; i++) {
            // Here look for a previous view.
            var oldView = dict[array[i].uid];
            if (oldView)
            {
                //oldView.visible = false;
                oldView.cocoaObject = array[i];
                this.subviews.push(oldView);
                this.subviewsElement.appendChild(oldView.element);
                oldView.toBeTrashed = false;
                conserved++;
            }
            else
            {
                this.appendCocoaObject(array[i]);
            }
        }
        console.log("From " + oldSubviews.length + " items, conserved " + conserved + ", created " + (array.length - conserved));

        // We are done, add back the child.
        if (oldSubviewsElement.parentNode)
            this.element.replaceChild(this.subviewsElement, oldSubviewsElement);
        else
            this.element.appendChild(this.subviewsElement);

        if (this.isAttached) {
            for (var i = 0; i < oldSubviews.length; i++) {
                if (oldSubviews[i].toBeTrashed)
                    oldSubviews[i].detachWithoutRemoving();
            }

            console.time("setCocoaObjects - updateVisibleItems");
            this.updateVisibleItems();
            console.timeEnd("setCocoaObjects - updateVisibleItems");
        }

        console.timeEnd("setCocoaObjects");

        console.profileEnd("setCocoaObjects");

    },

    /**
     * Callback from KVC Cocoa bindings
     */
    removeAllInsertedCocoaObjects: function()
    {
        // Instead of removing elements one by one,
        // remove the parent.
        var node = this.subviewsElement.cloneNode(false);
        this.subviewsElement.parentNode.removeChild(this.subviewsElement);
        this.subviewsElement = node;
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
    _shouldSyncSelectionWithArrayController: true,
    _arrayController: null,
    set arrayController(controller)
    {
        if (!controller)
            controller = null;

        Lunettes.willChange(this, "arrayController");
        this._arrayController = controller;
        Lunettes.didChange(this, "arrayController");

        if (controller) {
            if (this._shouldSyncSelectionWithArrayController) {
                var options = new Object;
                options["NSValueTransformerNameBindingOption"] = "VLCWebScriptObjectToIndexSet";
                Lunettes.connect(this._arrayController, "backendObject.selectionIndexes", this, "selectionIndexes", options);
            }
        }
    },
    get arrayController()
    {
        if (!this._arrayController)
            this._arrayController = null;
        return this._arrayController;
    },
    createArrayController: function()
    {
        console.assert(!this.arrayController, "There should be no arrayController");
        console.assert(this.subItemsKeyPath, "No keypath provided");
        var cocoaObject = this.cocoaObject;
        this.arrayController = cocoaObject.createArrayControllerFromKeyPath(this.subItemsKeyPath);
    },
    observe: function()
    {
        if (!this.arrayController)
            this.createArrayController();

        this.arrayController.addObserver(this, "arrangedObjects");
    }
}

ListView.prototype.detach.displayName = "ListView.detach()";
ListView.prototype.attach.displayName = "ListView.attach()";

