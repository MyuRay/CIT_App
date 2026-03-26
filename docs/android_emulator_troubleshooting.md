# Android エミュレータ 動作確認ガイド

## よくある問題と対処法

### 1. 「Lost connection to device」が出る

**原因**: デバッグ接続が切断された（エミュレータの不安定、ネットワーク断など）

**対処**:
```bash
# エミュレータをコールドブートで再起動
# Android Studio → Device Manager → エミュレータの ⋮ → Cold Boot Now

# または、エミュレータを一度終了してから再起動
adb emu kill
flutter emulators --launch Medium_Phone_API_36
# 起動完了を待ってから
flutter run -d emulator-5554
```

### 2. 「Unable to resolve host firestore.googleapis.com」が出る

**原因**: エミュレータのネットワーク/DNS が一時的に不安定

**対処**:
1. エミュレータ内でブラウザを開き、インターネット接続を確認
2. エミュレータをコールドブートで再起動
3. VPN を使用している場合は一度オフにして試す
4. ホストマシンのネットワークが安定しているか確認

### 3. アプリが起動しない / 白画面

**対処**:
```bash
# クリーンビルド
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### 4. デバイスが認識されない

**対処**:
```bash
# 接続デバイス確認
flutter devices

# ADB の再接続
adb kill-server
adb start-server
adb devices
```

## 推奨: 動作確認の手順

1. **エミュレータを起動**
   ```bash
   flutter emulators --launch Medium_Phone_API_36
   ```
   または Android Studio の Device Manager から起動

2. **起動完了を待つ**（ホーム画面が表示されるまで）

3. **アプリを実行**（デバイスIDを明示指定）
   ```bash
   flutter run -d emulator-5554
   ```

4. **サークル機能の確認**
   - ホーム画面で「サークル・部活」カードをタップ
   - 「診断する」または「体験会」で動作確認

## 補足

- サークル機能は **Firebase を使わずローカルデータ** のため、ネットワークが不安定でも診断・体験会一覧は表示されます
- 掲示板・学食など Firebase 連携機能はネットワーク必須です
