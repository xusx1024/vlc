/*****************************************************************************
 * network.cpp: the "network" dialog box
 *****************************************************************************
 * Copyright (C) 2002 VideoLAN
 *
 * Authors: Olivier Teuliere <ipkiss@via.ecp.fr>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111, USA.
 *****************************************************************************/

#include <vcl.h>
#pragma hdrstop

#include <vlc/vlc.h>
#include <vlc/intf.h>

#include "network.h"
#include "misc.h"
#include "win32_common.h"

#include "netutils.h"

//---------------------------------------------------------------------------
//#pragma package(smart_init)
#pragma link "CSPIN"
#pragma resource "*.dfm"

extern intf_thread_t *p_intfGlobal;

//---------------------------------------------------------------------------
__fastcall TNetworkDlg::TNetworkDlg( TComponent* Owner )
        : TForm( Owner )
{
        char *psz_channel_server;

        OldRadioValue = 0;

        /* server port */
        SpinEditUDPPort->Value = config_GetInt( p_intfGlobal, "server-port" );
        SpinEditMulticastPort->Value = config_GetInt( p_intfGlobal, "server-port" );

        /* channel server */
        if( config_GetInt( p_intfGlobal, "network-channel" ) )
        {
            RadioButtonCS->Checked = true;
            RadioButtonCSEnter( RadioButtonCS );
        }

        psz_channel_server = config_GetPsz( p_intfGlobal, "channel-server" );
        if( psz_channel_server )
        {
            ComboBoxCSAddress->Text = psz_channel_server;
            free( psz_channel_server );
        }

        SpinEditCSPort->Value = config_GetInt( p_intfGlobal, "channel-port" );

        Translate( this );
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::FormShow( TObject *Sender )
{
    p_intfGlobal->p_sys->p_window->NetworkStreamAction->Checked = true;
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::FormHide( TObject *Sender )
{
    p_intfGlobal->p_sys->p_window->NetworkStreamAction->Checked = false;
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::BitBtnCancelClick( TObject *Sender )
{
    Hide();
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::BitBtnOkClick( TObject *Sender )
{
    AnsiString      Source, Address;
    AnsiString      Channel = ComboBoxCSAddress->Text;
    unsigned int    i_channel_port = SpinEditCSPort->Value;
    unsigned int    i_port;
    playlist_t *    p_playlist;

    p_playlist = (playlist_t *)
        vlc_object_find( p_intfGlobal, VLC_OBJECT_PLAYLIST, FIND_ANYWHERE );
    if( p_playlist == NULL )
    {   
        return;
    }                        

    Hide();

    /* Check which option was chosen */
    switch( OldRadioValue )
    {
        /* UDP */
        case 0:
            config_PutInt( p_intfGlobal, "network-channel", FALSE );
            i_port = SpinEditUDPPort->Value;

            /* Build source name */
            Source = "udp:@:" + IntToStr( i_port );

            playlist_Add( p_playlist, Source.c_str(),
                          PLAYLIST_APPEND | PLAYLIST_GO, PLAYLIST_END );

            /* update the display */
            p_intfGlobal->p_sys->p_playwin->UpdateGrid( p_playlist );
            break;

        /* UDP Multicast */
        case 1:
            config_PutInt( p_intfGlobal, "network-channel", FALSE );
            Address = ComboBoxMulticastAddress->Text;
            i_port = SpinEditMulticastPort->Value;

            /* Build source name */
            Source = "udp:@" + Address + ":" + IntToStr( i_port );

            playlist_Add( p_playlist, Source.c_str(),
                          PLAYLIST_APPEND | PLAYLIST_GO, PLAYLIST_END );

            /* update the display */
            p_intfGlobal->p_sys->p_playwin->UpdateGrid( p_playlist );
            break;

        /* Channel server */
        case 2:
            config_PutInt( p_intfGlobal, "network-channel", TRUE );
            config_PutPsz( p_intfGlobal, "channel-server", Channel.c_str() );
            config_PutInt( p_intfGlobal, "channel-port", i_channel_port );

            if( p_intfGlobal->p_vlc->p_channel == NULL )
            {
                network_ChannelCreate( p_intfGlobal );
            }

            p_intfGlobal->p_sys->b_playing = 1;
            break;

        /* HTTP */
        case 3:
            config_PutInt( p_intfGlobal, "network-channel", FALSE );
            Address = EditHTTPURL->Text;

            /* Build source name with a basic test */
            if( Address.SubString( 1, 4 ) == "http" )
            {
                Source = Address;
            }
            else
            {
                Source = "http://" + Address;
            }

            playlist_Add( p_playlist, Source.c_str(),
                          PLAYLIST_APPEND | PLAYLIST_GO, PLAYLIST_END );

            /* update the display */
            p_intfGlobal->p_sys->p_playwin->UpdateGrid( p_playlist );
            break;
    }

    vlc_object_release( p_playlist );
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::ChangeEnabled( int i_selected )
{
    switch( i_selected )
    {
        case 0:
            LabelUDPPort->Enabled = NOT( LabelUDPPort->Enabled );
            SpinEditUDPPort->Enabled = NOT( SpinEditUDPPort->Enabled );
            break;
        case 1:
            LabelMulticastAddress->Enabled =
                    NOT( LabelMulticastAddress->Enabled );
            ComboBoxMulticastAddress->Enabled =
                    NOT( ComboBoxMulticastAddress->Enabled );
            LabelMulticastPort->Enabled = NOT( LabelMulticastPort->Enabled );
            SpinEditMulticastPort->Enabled = NOT( SpinEditMulticastPort->Enabled );
            break;
        case 2:
            LabelCSAddress->Enabled = NOT( LabelCSAddress->Enabled );
            ComboBoxCSAddress->Enabled = NOT( ComboBoxCSAddress->Enabled );
            LabelCSPort->Enabled = NOT( LabelCSPort->Enabled );
            SpinEditCSPort->Enabled = NOT( SpinEditCSPort->Enabled );
            break;
        case 3:
            LabelHTTPURL->Enabled = NOT( LabelHTTPURL->Enabled );
            EditHTTPURL->Enabled = NOT( EditHTTPURL->Enabled );
            break;
    }
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::RadioButtonUDPEnter( TObject *Sender )
{
    ChangeEnabled( OldRadioValue );
    OldRadioValue = 0;
    ChangeEnabled( OldRadioValue );
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::RadioButtonMulticastEnter( TObject *Sender )
{
    ChangeEnabled( OldRadioValue );
    OldRadioValue = 1;
    ChangeEnabled( OldRadioValue );
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::RadioButtonCSEnter( TObject *Sender )
{
    ChangeEnabled( OldRadioValue );
    OldRadioValue = 2;
    ChangeEnabled( OldRadioValue );
}
//---------------------------------------------------------------------------
void __fastcall TNetworkDlg::RadioButtonHTTPEnter( TObject *Sender )
{
    ChangeEnabled( OldRadioValue );
    OldRadioValue = 3;
    ChangeEnabled( OldRadioValue );
}
//---------------------------------------------------------------------------

