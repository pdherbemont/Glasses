/**
 * A view for a Media
 * @constructor
 * @param {CocoaObject} cocoaObject
 * @param {Object} parent
 * @param {string} elementTag
 */
var ListItemView = function(cocoaObject, parent, elementTag)
{
    this.parent = parent;

    this.cocoaObject = cocoaObject;

    this.element = document.createElement(elementTag);
    this.element.className = "item";

    this.isAttached = false;
}

ListItemView.prototype = {
    /**
     * @param {Node=} parentElement
     */
    attach: function(parentElement)
    {
        console.assert(!this.isAttached, "shouldn't be attached");

        parentElement.appendChild(this.element);

        this.isAttached = true;
    },

    detachWithoutRemoving: function()
    {
        this.visible = false;
        this.isAttached = false;
    },
    detach: function()
    {
        this.element.detach();
    },

    _visible: false,
    get visible()
    {
        return this._visible;
    },

    set visible(visible)
    {
        console.assert(this.isAttached);

        if (this._visible == visible)
            return;

        this._visible = visible;
        if (visible) {
            this.element.addEventListener('mousedown', this.mouseDown.bind(this), false);
            this.element.addEventListener('dblclick', this.mouseDoubleClicked.bind(this), false);
            this.element.addEventListener('dragstart', this.dragStarted.bind(this), false);
        }
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    dragStarted: function(event)
    {
        event.effectAllowed = "copyMove";
        event.dataTransfer.setData("application/lunettes-item", this);
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    mouseDown: function(event)
    {
        if (!this.parent)
            return;

        this.parent.select(this);
        event.stopPropagation();
    },

    /**
     * Event Handler
     * @param {Event} event
     */
    mouseDoubleClicked: function(event)
    {
        this.action();
        event.stopPropagation();
    },

    /**
     * When double clicked
     */
    action: function()
    {
    }
};

ListItemView.prototype.detach.displayName = "ListItemView.detach()";
ListItemView.prototype.attach.displayName = "ListItemView.attach()";
ListItemView.prototype.__lookupSetter__("visible").displayName = "ListItemView.setVisible()";

