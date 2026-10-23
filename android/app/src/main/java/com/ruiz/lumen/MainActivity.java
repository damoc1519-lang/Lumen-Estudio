package com.ruiz.lumen;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private static final String HOME = "https://damoc1519-lang.github.io/Lumen-Estudio/";
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(248, 247, 244));
        getWindow().setNavigationBarColor(Color.rgb(248, 247, 244));
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR | View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(248, 247, 244));
        webView.setOnApplyWindowInsetsListener((view, insets) -> {
            view.setPadding(0, insets.getSystemWindowInsetTop(), 0, insets.getSystemWindowInsetBottom());
            return insets;
        });
        webView.requestApplyInsets();
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setAllowFileAccess(false);
        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) {
                Uri uri = Uri.parse(url);
                if ("damoc1519-lang.github.io".equals(uri.getHost())) return false;
                startActivity(new Intent(Intent.ACTION_VIEW, uri));
                return true;
            }
        });
        webView.setWebChromeClient(new WebChromeClient());
        setContentView(webView);
        if (savedInstanceState != null) webView.restoreState(savedInstanceState); else webView.loadUrl(HOME);
    }

    @Override protected void onSaveInstanceState(Bundle outState) { webView.saveState(outState); super.onSaveInstanceState(outState); }
    @Override public void onBackPressed() { if (webView != null && webView.canGoBack()) webView.goBack(); else super.onBackPressed(); }
}
