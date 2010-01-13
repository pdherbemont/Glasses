/**************************************************
 * dom-drag.js
 * 09.25.2001
 * www.youngpup.net
 **************************************************
 * 10.28.2001 - fixed minor bug where events
 * sometimes fired off the handle, not the root.
 **************************************************/

/**
 * @constructor
 */
var Drag = function ()
{

}

Drag.prototype = {

	target: null,

    parseIntDec: function parseIntDec(a) {
        return parseInt(a, 10);
    },

	init: function(o)
	{
		o.addEventListener("mousedown", this.start.bind(this));
        this.target = o;
    },

	start: function(e)
	{
		if (e.srcElement.nodeName != "DIV")
			return;

        var o = this.target;
		var y = this.parseIntDec(o.style.top);
		var x = this.parseIntDec(o.style.left);

		o.originalMouseX = e.clientX;
		o.originalMouseY = e.clientY;
		o.originalX = x;
		o.originalY = y;

        console.assert(!this._drag);

        this._drag = this.drag.bind(this);
        this._end = this.end.bind(this);
        document.addEventListener("mousemove", this._drag, false);
        document.addEventListener("mouseup", this._end, false);
        return false;
	},

	drag: function(e)
	{
		var o = this.target;

		var ey	= e.clientY;
		var ex	= e.clientX;
		var nx, ny;

		nx = o.originalX + (ex - o.originalMouseX);
		ny = o.originalY + (ey - o.originalMouseY);

        o.style.left = nx + "px";
		o.style.top = ny + "px";

        return false;
	},

	end: function()
	{
        document.removeEventListener("mousemove", this._drag, false);
        document.removeEventListener("mouseup", this._end, false);
        this._drag = null;
        this._end = null;
	}
};

window.dragController = new Drag();
