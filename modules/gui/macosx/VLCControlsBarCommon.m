/*****************************************************************************
 * VLCControlsBarCommon.m: MacOS X interface module
 *****************************************************************************
 * Copyright (C) 2012-2016 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne -at- videolan -dot- org>
 *          David Fuhrmann <david dot fuhrmann at googlemail dot com>
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

#import "VLCControlsBarCommon.h"
#import "VLCMain.h"
#import "VLCCoreInteraction.h"
#import "VLCMainMenu.h"
#import "VLCPlaylist.h"
#import "CompatibilityFixes.h"

/*****************************************************************************
 * VLCControlsBarCommon
 *
 *  Holds all outlets, actions and code common for controls bar in detached
 *  and in main window.
 *****************************************************************************/

@interface VLCControlsBarCommon ()
{
    NSImage * _pauseImage;
    NSImage * _pressedPauseImage;
    NSImage * _playImage;
    NSImage * _pressedPlayImage;

    NSTimeInterval last_fwd_event;
    NSTimeInterval last_bwd_event;
    BOOL just_triggered_next;
    BOOL just_triggered_previous;
}
@end

@implementation VLCControlsBarCommon

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _darkInterface = var_InheritBool(getIntf(), "macosx-interfacestyle");
    _nativeFullscreenMode = var_InheritBool(getIntf(), "macosx-nativefullscreenmode");

    [self.dropView setDrawBorder: NO];

    [self.playButton setToolTip: _NS("Play/Pause")];
    [[self.playButton cell] accessibilitySetOverrideValue:_NS("Click to play or pause the current media.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.playButton cell] accessibilitySetOverrideValue:[self.playButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.backwardButton setToolTip: _NS("Backward")];
    [[self.backwardButton cell] accessibilitySetOverrideValue:_NS("Click to go to the previous playlist item. Hold to skip backward through the current media.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.backwardButton cell] accessibilitySetOverrideValue:[self.backwardButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.forwardButton setToolTip: _NS("Forward")];
    [[self.forwardButton cell] accessibilitySetOverrideValue:_NS("Click to go to the next playlist item. Hold to skip forward through the current media.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.forwardButton cell] accessibilitySetOverrideValue:[self.forwardButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.timeSlider setToolTip: _NS("Position")];
    [[self.timeSlider cell] accessibilitySetOverrideValue:_NS("Click and move the mouse while keeping the button pressed to use this slider to change current playback position.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.timeSlider cell] accessibilitySetOverrideValue:[self.timeSlider toolTip] forAttribute:NSAccessibilityTitleAttribute];
    if (_darkInterface)
        [self.timeSlider setSliderStyleDark];

    [self.fullscreenButton setToolTip: _NS("Toggle Fullscreen mode")];
    [[self.fullscreenButton cell] accessibilitySetOverrideValue:_NS("Click to enable fullscreen video playback.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.fullscreenButton cell] accessibilitySetOverrideValue:[self.fullscreenButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    if (!_darkInterface) {
        [self.bottomBarView setDark:NO];

        [self.backwardButton setImage: imageFromRes(@"backward-3btns")];
        [self.backwardButton setAlternateImage: imageFromRes(@"backward-3btns-pressed")];
        _playImage = imageFromRes(@"play");
        _pressedPlayImage = imageFromRes(@"play-pressed");
        _pauseImage = imageFromRes(@"pause");
        _pressedPauseImage = imageFromRes(@"pause-pressed");
        [self.forwardButton setImage: imageFromRes(@"forward-3btns")];
        [self.forwardButton setAlternateImage: imageFromRes(@"forward-3btns-pressed")];

        [self.fullscreenButton setImage: imageFromRes(@"fullscreen-one-button")];
        [self.fullscreenButton setAlternateImage: imageFromRes(@"fullscreen-one-button-pressed")];
    } else {
        [self.bottomBarView setDark:YES];

        [self.backwardButton setImage: imageFromRes(@"backward-3btns-dark")];
        [self.backwardButton setAlternateImage: imageFromRes(@"backward-3btns-dark-pressed")];
        _playImage = imageFromRes(@"play_dark");
        _pressedPlayImage = imageFromRes(@"play-pressed_dark");
        _pauseImage = imageFromRes(@"pause_dark");
        _pressedPauseImage = imageFromRes(@"pause-pressed_dark");
        [self.forwardButton setImage: imageFromRes(@"forward-3btns-dark")];
        [self.forwardButton setAlternateImage: imageFromRes(@"forward-3btns-dark-pressed")];

        [self.fullscreenButton setImage: imageFromRes(@"fullscreen-one-button-pressed_dark")];
        [self.fullscreenButton setAlternateImage: imageFromRes(@"fullscreen-one-button-pressed_dark")];
    }

    [self.playButton setImage: _playImage];
    [self.playButton setAlternateImage: _pressedPlayImage];

    NSColor *timeFieldTextColor;
    if (!var_InheritBool(getIntf(), "macosx-interfacestyle"))
        timeFieldTextColor = [NSColor colorWithCalibratedRed:0.229 green:0.229 blue:0.229 alpha:100.0];
    else
        timeFieldTextColor = [NSColor colorWithCalibratedRed:0.64 green:0.64 blue:0.64 alpha:100.0];
    [self.timeField setTextColor: timeFieldTextColor];
    [self.timeField setFont:[NSFont titleBarFontOfSize:10.0]];
    [self.timeField setAlignment: NSCenterTextAlignment];
    [self.timeField setNeedsDisplay:YES];
    [self.timeField setRemainingIdentifier:@"DisplayTimeAsTimeRemaining"];

    // remove fullscreen button for lion fullscreen
    if (_nativeFullscreenMode) {
        self.fullscreenButtonWidthConstraint.constant = 0;
    }

    if (config_GetInt(getIntf(), "macosx-show-playback-buttons"))
        [self toggleForwardBackwardMode: YES];

}

- (CGFloat)height
{
    return [self.bottomBarView frame].size.height;
}

- (void)toggleForwardBackwardMode:(BOOL)b_alt
{
    if (b_alt == YES) {
        /* change the accessibility help for the backward/forward buttons accordingly */
        [[self.backwardButton cell] accessibilitySetOverrideValue:_NS("Click and hold to skip backward through the current media.") forAttribute:NSAccessibilityDescriptionAttribute];
        [[self.forwardButton cell] accessibilitySetOverrideValue:_NS("Click and hold to skip forward through the current media.") forAttribute:NSAccessibilityDescriptionAttribute];

        [self.forwardButton setAction:@selector(alternateForward:)];
        [self.backwardButton setAction:@selector(alternateBackward:)];

    } else {
        /* change the accessibility help for the backward/forward buttons accordingly */
        [[self.backwardButton cell] accessibilitySetOverrideValue:_NS("Click to go to the previous playlist item. Hold to skip backward through the current media.") forAttribute:NSAccessibilityDescriptionAttribute];
        [[self.forwardButton cell] accessibilitySetOverrideValue:_NS("Click to go to the next playlist item. Hold to skip forward through the current media.") forAttribute:NSAccessibilityDescriptionAttribute];

        [self.forwardButton setAction:@selector(fwd:)];
        [self.backwardButton setAction:@selector(bwd:)];
    }
}

#pragma mark -
#pragma mark Button Actions

- (IBAction)play:(id)sender
{
    [[VLCCoreInteraction sharedInstance] playOrPause];
}

- (void)resetPreviousButton
{
    if (([NSDate timeIntervalSinceReferenceDate] - last_bwd_event) >= 0.35) {
        // seems like no further event occurred, so let's switch the playback item
        [[VLCCoreInteraction sharedInstance] previous];
        just_triggered_previous = NO;
    }
}

- (void)resetBackwardSkip
{
    // the user stopped skipping, so let's allow him to change the item
    if (([NSDate timeIntervalSinceReferenceDate] - last_bwd_event) >= 0.35)
        just_triggered_previous = NO;
}

- (IBAction)bwd:(id)sender
{
    if (!just_triggered_previous) {
        just_triggered_previous = YES;
        [self performSelector:@selector(resetPreviousButton)
                   withObject: NULL
                   afterDelay:0.40];
    } else {
        if (([NSDate timeIntervalSinceReferenceDate] - last_fwd_event) > 0.16) {
            // we just skipped 4 "continous" events, otherwise we are too fast
            [[VLCCoreInteraction sharedInstance] backwardExtraShort];
            last_bwd_event = [NSDate timeIntervalSinceReferenceDate];
            [self performSelector:@selector(resetBackwardSkip)
                       withObject: NULL
                       afterDelay:0.40];
        }
    }
}

- (void)resetNextButton
{
    if (([NSDate timeIntervalSinceReferenceDate] - last_fwd_event) >= 0.35) {
        // seems like no further event occurred, so let's switch the playback item
        [[VLCCoreInteraction sharedInstance] next];
        just_triggered_next = NO;
    }
}

- (void)resetForwardSkip
{
    // the user stopped skipping, so let's allow him to change the item
    if (([NSDate timeIntervalSinceReferenceDate] - last_fwd_event) >= 0.35)
        just_triggered_next = NO;
}

- (IBAction)fwd:(id)sender
{
    if (!just_triggered_next) {
        just_triggered_next = YES;
        [self performSelector:@selector(resetNextButton)
                   withObject: NULL
                   afterDelay:0.40];
    } else {
        if (([NSDate timeIntervalSinceReferenceDate] - last_fwd_event) > 0.16) {
            // we just skipped 4 "continous" events, otherwise we are too fast
            [[VLCCoreInteraction sharedInstance] forwardExtraShort];
            last_fwd_event = [NSDate timeIntervalSinceReferenceDate];
            [self performSelector:@selector(resetForwardSkip)
                       withObject: NULL
                       afterDelay:0.40];
        }
    }
}

// alternative actions for forward / backward buttons when next / prev are activated
- (IBAction)alternateForward:(id)sender
{
    [[VLCCoreInteraction sharedInstance] forwardExtraShort];
}

- (IBAction)alternateBackward:(id)sender
{
    [[VLCCoreInteraction sharedInstance] backwardExtraShort];
}

- (IBAction)timeSliderAction:(id)sender
{
    float f_updated;
    input_thread_t * p_input;

    switch([[NSApp currentEvent] type]) {
        case NSLeftMouseUp:
            /* Ignore mouse up, as this is a continous slider and
             * when the user does a single click to a position on the slider,
             * the action is called twice, once for the mouse down and once
             * for the mouse up event. This results in two short seeks one
             * after another to the same position, which results in weird
             * audio quirks.
             */
            return;
        case NSLeftMouseDown:
        case NSLeftMouseDragged:
            f_updated = [sender floatValue];
            break;

        default:
            return;
    }
    p_input = pl_CurrentInput(getIntf());
    if (p_input != NULL) {
        vlc_value_t pos;
        NSString * o_time;

        pos.f_float = f_updated / 10000.;
        var_Set(p_input, "position", pos);
        [self.timeSlider setFloatValue: f_updated];

        o_time = [[VLCStringUtility sharedInstance] getCurrentTimeAsString: p_input negative:[self.timeField timeRemaining]];
        [self.timeField setStringValue: o_time];
        vlc_object_release(p_input);
    }
}

- (IBAction)fullscreen:(id)sender
{
    [[VLCCoreInteraction sharedInstance] toggleFullscreen];
}

#pragma mark -
#pragma mark Updaters

- (void)updateTimeSlider
{
    input_thread_t * p_input;
    p_input = pl_CurrentInput(getIntf());

    [self.timeSlider setHidden:NO];

    if (!p_input) {
        // Nothing playing
        [self.timeSlider setKnobHidden:YES];
        [self.timeSlider setFloatValue: 0.0];
        [self.timeField setStringValue: @"00:00"];
        [self.timeSlider setIndefinite:NO];
        [self.timeSlider setEnabled:NO];
        return;
    }

    [self.timeSlider setKnobHidden:NO];

    vlc_value_t pos;
    var_Get(p_input, "position", &pos);
    [self.timeSlider setFloatValue:(10000. * pos.f_float)];

    mtime_t dur = input_item_GetDuration(input_GetItem(p_input));
    if (dur == -1) {
        // No duration, disable slider
        [self.timeSlider setEnabled:NO];
    } else {
        input_state_e inputState = input_GetState(p_input);
        bool buffering = (inputState == INIT_S || inputState == OPENING_S);
        [self.timeSlider setIndefinite:buffering];
    }

    NSString *time = [[VLCStringUtility sharedInstance] getCurrentTimeAsString:p_input
                                                                      negative:[self.timeField timeRemaining]];
    [self.timeField setStringValue:time];
    [self.timeField setNeedsDisplay:YES];

    vlc_object_release(p_input);
}

- (void)updateControls
{
    bool b_plmul = false;
    bool b_seekable = false;
    bool b_chapters = false;
    bool b_buffering = false;

    playlist_t * p_playlist = pl_Get(getIntf());

    PL_LOCK;
    b_plmul = playlist_CurrentSize(p_playlist) > 1;
    PL_UNLOCK;

    input_thread_t * p_input = playlist_CurrentInput(p_playlist);

    if (p_input) {
        input_state_e inputState = input_GetState(p_input);
        if (inputState == INIT_S || inputState == OPENING_S)
            b_buffering = YES;

        /* seekable streams */
        b_seekable = var_GetBool(p_input, "can-seek");

        /* chapters & titles */
        //FIXME! b_chapters = p_input->stream.i_area_nb > 1;

        vlc_object_release(p_input);
    }

    [self.timeSlider setEnabled: b_seekable];

    [self.forwardButton setEnabled: (b_seekable || b_plmul || b_chapters)];
    [self.backwardButton setEnabled: (b_seekable || b_plmul || b_chapters)];
}

- (void)setPause
{
    [self.playButton setImage: _pauseImage];
    [self.playButton setAlternateImage: _pressedPauseImage];
    [self.playButton setToolTip: _NS("Pause")];
}

- (void)setPlay
{
    [self.playButton setImage: _playImage];
    [self.playButton setAlternateImage: _pressedPlayImage];
    [self.playButton setToolTip: _NS("Play")];
}

- (void)setFullscreenState:(BOOL)b_fullscreen
{
    if (!self.nativeFullscreenMode)
        [self.fullscreenButton setState:b_fullscreen];
}

@end
