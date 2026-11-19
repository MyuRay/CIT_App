import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var scheduleImageChannel: FlutterMethodChannel?
  private var scheduleImageSaveInProgress = false
  private var legacyPhotoResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase は firebase_core プラグイン経由で Dart 側の Firebase.initializeApp() が行う
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "ScheduleImageSavePlugin") {
      let channel = FlutterMethodChannel(
        name: "jp.ac.chibakoudai.citapp/schedule_image",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(FlutterError(code: "save_failed", message: "保存機能を利用できません。", details: nil))
          return
        }
        self.handleScheduleImage(call, result: result)
      }
      scheduleImageChannel = channel
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleScheduleImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "saveImage" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let arguments = call.arguments as? [String: Any],
      let bytes = arguments["bytes"] as? FlutterStandardTypedData,
      !bytes.data.isEmpty,
      let name = arguments["name"] as? String,
      name.range(of: "^[A-Za-z0-9_-]{1,120}\\.png$", options: .regularExpression) != nil else {
      result(FlutterError(code: "save_failed", message: "保存する画像またはファイル名が正しくありません。", details: nil))
      return
    }
    guard !scheduleImageSaveInProgress else {
      result(FlutterError(code: "save_failed", message: "画像の保存が完了するまでお待ちください。", details: nil))
      return
    }
    scheduleImageSaveInProgress = true
    let completion: FlutterResult = { value in
      DispatchQueue.main.async {
        self.scheduleImageSaveInProgress = false
        result(value)
      }
    }

    if #available(iOS 14, *) {
      let saveIfAuthorized: (PHAuthorizationStatus) -> Void = { status in
        guard status == .authorized || status == .limited else {
          completion(self.photoPermissionError())
          return
        }
        PHPhotoLibrary.shared().performChanges({
          let options = PHAssetResourceCreationOptions()
          options.originalFilename = name
          PHAssetCreationRequest.forAsset().addResource(
            with: .photo, data: bytes.data, options: options
          )
        }) { success, error in
          if success {
            completion(nil)
          } else if PHPhotoLibrary.authorizationStatus(for: .addOnly) == .denied ||
            PHPhotoLibrary.authorizationStatus(for: .addOnly) == .restricted {
            completion(self.photoPermissionError())
          } else {
            completion(FlutterError(
              code: "save_failed",
              message: "画像を保存できませんでした。空き容量などを確認して再度お試しください。",
              details: error?.localizedDescription
            ))
          }
        }
      }
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      if status == .notDetermined {
        PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: saveIfAuthorized)
      } else {
        saveIfAuthorized(status)
      }
    } else {
      // iOS 13 has no PHAccessLevel API. UIKit requests add-only authorization
      // using NSPhotoLibraryAddUsageDescription when saving the provided image.
      guard let image = UIImage(data: bytes.data) else {
        completion(FlutterError(code: "save_failed", message: "保存する画像が正しくありません。", details: nil))
        return
      }
      legacyPhotoResult = completion
      UIImageWriteToSavedPhotosAlbum(
        image, self, #selector(scheduleImage(_:didFinishSavingWithError:contextInfo:)), nil
      )
    }
  }

  private func photoPermissionError() -> FlutterError {
    FlutterError(
      code: "permission_denied",
      message: "写真への保存が許可されていません。設定から写真の追加を許可してください。",
      details: nil
    )
  }

  @objc private func scheduleImage(
    _ image: UIImage,
    didFinishSavingWithError error: NSError?,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    guard let result = legacyPhotoResult else { return }
    legacyPhotoResult = nil
    if let error = error {
      if error.code == -3311 || PHPhotoLibrary.authorizationStatus() == .denied ||
        PHPhotoLibrary.authorizationStatus() == .restricted {
        result(photoPermissionError())
      } else {
        result(FlutterError(
          code: "save_failed",
          message: "画像を保存できませんでした。空き容量などを確認して再度お試しください。",
          details: error.localizedDescription
        ))
      }
    } else {
      result(nil)
    }
  }
}
