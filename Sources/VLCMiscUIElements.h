/*****************************************************************************
 * VLCMiscUIElements.h: various unspecific UI elements
 *****************************************************************************
 * Copyright (C) 2003-2009 the VideoLAN team
 * $Id: $
 *
 * Authors: Jon Lech Johansen <jon-vl@nanocrew.net>
 *          Felix Paul Kühne <fkuehne at videolan dot org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <ApplicationServices/ApplicationServices.h>

/*****************************************************************************
 * MPSlider
 *****************************************************************************/

@interface MPSlider : NSSlider

@end

/*****************************************************************************
 * ITSlider
 *****************************************************************************/

@interface ITSlider : NSSlider

@end

/*****************************************************************************
 * ITSliderCell
 *****************************************************************************/

@interface ITSliderCell : NSSliderCell
{
    NSImage *_knobOff;
    NSImage *_knobOn;
    BOOL b_mouse_down;
}
- (void)controlTintChanged;

@end
