package com.Gonbal_My_Game;

import android.app.Activity;
import android.content.Context;
import android.nfc.NdefMessage;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.Ndef;
import android.os.Bundle;
import android.util.Log;

public class NfcReaderHelper implements NfcAdapter.ReaderCallback {

    private static final String TAG = "NfcReaderHelper";
    private NfcAdapter mNfcAdapter;
    private Context mContext;
    private long mNativePtr;
    private Tag mCachedTag;

    // Native 方法
    private native void onNdefDataReceived(long ptr, byte[] data);
    private native void onNfcConnectedNative(long ptr);
    private native void onNfcDisconnectedNative(long ptr);
    private native void onNfcErrorNative(long ptr, String message);

    public NfcReaderHelper(long ptr, Context context, boolean isServer) {
        Log.d(TAG, "=== Constructor called, ptr=" + ptr + ", context=" + context + ", isServer=" + isServer);
        mNativePtr = ptr;
        mContext = context;

        if (mContext == null) {
            Log.e(TAG, "Context 为空，NFC 功能不可用");
            onNfcErrorNative(ptr, "Context 为空");
            return;
        }

        Log.d(TAG, "Getting NFC adapter...");
        mNfcAdapter = NfcAdapter.getDefaultAdapter(mContext);
        if (mNfcAdapter == null) {
            Log.e(TAG, "设备不支持 NFC");
            onNfcErrorNative(ptr, "设备不支持 NFC");
            return;
        }
        Log.d(TAG, "NFC adapter obtained: " + mNfcAdapter);

        Log.d(TAG, "=== NfcReaderHelper created successfully, ptr=" + ptr);
    }

    public boolean enableReaderMode() {
        Log.d(TAG, "=== enableReaderMode called ===");
        if (mNfcAdapter == null) {
            onNfcErrorNative(mNativePtr, "NFC 适配器不可用");
            return false;
        }
        if (mContext == null) {
            onNfcErrorNative(mNativePtr, "Context 为空");
            return false;
        }

        Activity activity;
        try {
            activity = (Activity) mContext;
        } catch (ClassCastException e) {
            Log.e(TAG, "Context is not an Activity: " + e.getMessage());
            onNfcErrorNative(mNativePtr, "Context 不是 Activity");
            return false;
        }

        int flags = NfcAdapter.FLAG_READER_NFC_A |
                    NfcAdapter.FLAG_READER_NFC_B |
                    NfcAdapter.FLAG_READER_NFC_F |
                    NfcAdapter.FLAG_READER_NFC_V |
                    NfcAdapter.FLAG_READER_NFC_BARCODE;

        try {
            mNfcAdapter.enableReaderMode(activity, this, flags, new Bundle());
            Log.d(TAG, "enableReaderMode success");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "enableReaderMode 失败: " + e.getMessage(), e);
            onNfcErrorNative(mNativePtr, "启用读卡器模式失败: " + e.getMessage());
            return false;
        }
    }

    public void disableReaderMode() {
        Log.d(TAG, "=== disableReaderMode called ===");
        if (mNfcAdapter == null || mContext == null) return;

        Activity activity;
        try {
            activity = (Activity) mContext;
        } catch (ClassCastException e) {
            Log.e(TAG, "disableReaderMode: Context 不是 Activity: " + e.getMessage());
            return;
        }

        try {
            mNfcAdapter.disableReaderMode(activity);
            Log.d(TAG, "disableReaderMode success");
        } catch (Exception e) {
            Log.e(TAG, "disableReaderMode 失败: " + e.getMessage(), e);
        }
    }

    @Override
    public void onTagDiscovered(Tag tag) {
        Log.d(TAG, "=== onTagDiscovered CALLED ===");
        if (tag == null) {
            Log.e(TAG, "Tag is null!");
            return;
        }
        Log.d(TAG, "Tag ID: " + bytesToHex(tag.getId()));
        Log.d(TAG, "Tag tech list: " + String.join(", ", tag.getTechList()));

        mCachedTag = tag;

        // 读取 NDEF 消息
        readNdefMessage(tag);
    }

    private void readNdefMessage(Tag tag) {
        try {
            Log.d(TAG, "Attempting to get Ndef from tag...");
            Ndef ndef = Ndef.get(tag);
            if (ndef != null) {
                Log.d(TAG, "Ndef obtained successfully");
                ndef.connect();
                Log.d(TAG, "NDEF connected, reading message...");
                NdefMessage ndefMessage = ndef.getNdefMessage();
                ndef.close();
                Log.d(TAG, "NDEF closed");

                if (ndefMessage != null) {
                    byte[] payload = ndefMessage.toByteArray();
                    Log.d(TAG, "NDEF message read, size=" + payload.length + " bytes");
                    Log.d(TAG, "NDEF message payload (hex): " + bytesToHex(payload));
                    Log.d(TAG, "Calling onNdefDataReceived...");
                    onNdefDataReceived(mNativePtr, payload);
                    Log.d(TAG, "Calling onNfcConnectedNative...");
                    onNfcConnectedNative(mNativePtr);
                    Log.d(TAG, "onTagDiscovered completed successfully");
                } else {
                    Log.w(TAG, "NDEF 消息为空 (ndefMessage is null)");
                    onNfcErrorNative(mNativePtr, "NDEF 消息为空");
                }
            } else {
                Log.w(TAG, "Tag 不是 NDEF 格式 (Ndef.get(tag) returned null)");
                Log.d(TAG, "Tech list: " + String.join(", ", tag.getTechList()));
            }
        } catch (Exception e) {
            Log.e(TAG, "读取 NDEF 失败: " + e.getMessage(), e);
            onNfcErrorNative(mNativePtr, "读取 NDEF 失败: " + e.getMessage());
        }
    }

    // 辅助方法：将字节数组转为十六进制字符串
    private String bytesToHex(byte[] bytes) {
        if (bytes == null) return "null";
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X ", b));
        }
        return sb.toString().trim();
    }
}
