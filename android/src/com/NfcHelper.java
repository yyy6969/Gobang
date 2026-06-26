package com;

import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.NdefMessage;
import android.nfc.NdefRecord;
import android.nfc.tech.Ndef;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

public class NfcHelper implements NfcAdapter.ReaderCallback {
    private static final String TAG = "NfcHelper";
    private static long nativePtr = 0;
    private static boolean mIsHost = false;
    private static byte[] mPendingPayload = null;

    public static void setNativePtr(long ptr) {
        nativePtr = ptr;
    }

    public static void setHostMode(boolean isHost, byte[] payload) {
        mIsHost = isHost;
        mPendingPayload = payload;
    }

    public static boolean startReader(Activity activity) {
        Log.d("NfcHelper", "startReader called");
        NfcAdapter adapter = NfcAdapter.getDefaultAdapter(activity);
        if (adapter == null) return false;
        Bundle options = new Bundle();
        options.putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 5000);
        adapter.enableReaderMode(activity, new NfcHelper(),
                NfcAdapter.FLAG_READER_NFC_A |
                NfcAdapter.FLAG_READER_NFC_B |
                NfcAdapter.FLAG_READER_NFC_F |
                NfcAdapter.FLAG_READER_NFC_V |
                NfcAdapter.FLAG_READER_NFC_BARCODE,
                options);
        return true;
    }

    public static void stopReader(Activity activity) {
        NfcAdapter adapter = NfcAdapter.getDefaultAdapter(activity);
        if (adapter != null) {
            adapter.disableReaderMode(activity);
        }
    }

    @Override
    public void onTagDiscovered(Tag tag) {
        Log.d(TAG, "Tag discovered");
        Ndef ndef = Ndef.get(tag);
        if (ndef == null) return;
        try {
            ndef.connect();
            NdefMessage ndefMessage = ndef.getNdefMessage();
            if (ndefMessage == null) {
                if (mIsHost && mPendingPayload != null) {
                    NdefRecord record = NdefRecord.createMime("application/json", mPendingPayload);
                    ndef.writeNdefMessage(new NdefMessage(new NdefRecord[]{record}));
                    Log.d(TAG, "Host wrote NDEF");
                }
                ndef.close();
                return;
            }
            NdefRecord[] records = ndefMessage.getRecords();
            if (records.length > 0) {
                byte[] payload = records[0].getPayload();
                if (nativePtr != 0) {
                    nativeOnNdefReceived(nativePtr, payload);
                }
            }
            ndef.close();
        } catch (Exception e) {
            Log.e(TAG, "error", e);
        }
    }

    private static native void nativeOnNdefReceived(long ptr, byte[] payload);
}