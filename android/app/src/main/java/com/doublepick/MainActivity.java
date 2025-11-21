package com.doublepick;

import android.content.Intent;
import android.os.Build;
import android.provider.Settings;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "app.settings.channel";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if (call.method.equals("openNotificationSettings")) {
                openNotificationSettings();
                result.success(true);
            } else {
                result.notImplemented();
            }
        });
    }

    private void openNotificationSettings() {
        Intent intent = new Intent();

        // ⚡ Radi na Xiaomi / Redmi / Poco
        intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
        intent.putExtra("app_package", getPackageName());
        intent.putExtra("app_uid", getApplicationInfo().uid);

        // ⚡ Radi na novijim Androidima
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, getPackageName());
        }

        startActivity(intent);
    }
}
