//
//  YPCameraSettingsHelper.swift
//  YPImagePicker
//
//  Created by Marcin Rudnicki on 03/09/2019.
//  Copyright © 2019 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

class YPCameraSettingsHelper: NSObject {

    func changeTemperature(device: AVCaptureDevice, temperature: Double, completion: (Int)->()) {
        let currentTemperatureAndTint = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)

        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: Float(temperature), tint: currentTemperatureAndTint.tint)

        setWhiteBalanceGains(device: device, gains: device.deviceWhiteBalanceGains(for: temperatureAndTint))
        completion(Int(temperature))
    }

    func changeTint(device: AVCaptureDevice, tint: Double, completion: (Int)->()) {
        let currentTemperatureAndTint = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)

        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: currentTemperatureAndTint.temperature, tint: Float(tint))

        setWhiteBalanceGains(device: device, gains: device.deviceWhiteBalanceGains(for: temperatureAndTint))
        completion(Int(tint))
    }

    private func normalizedGains(device: AVCaptureDevice, gains: AVCaptureDevice.WhiteBalanceGains) -> AVCaptureDevice.WhiteBalanceGains {
        var g = gains

        g.redGain = max(1.0, g.redGain)
        g.greenGain = max(1.0, g.greenGain)
        g.blueGain = max(1.0, g.blueGain)

        g.redGain = min(device.maxWhiteBalanceGain, g.redGain)
        g.greenGain = min(device.maxWhiteBalanceGain, g.greenGain)
        g.blueGain = min(device.maxWhiteBalanceGain, g.blueGain)

        return g
    }

    private func setWhiteBalanceGains(device: AVCaptureDevice, gains: AVCaptureDevice.WhiteBalanceGains) {
        do {
            try device.lockForConfiguration()
            let normGains = normalizedGains(device: device, gains: gains)
            device.setWhiteBalanceModeLocked(with: normGains, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("YPCameraVC -> Can't set white balance for some reason.")
        }
    }

    func enableAutoWhiteBalance(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance
            } else {
                print("White balance mode auto is not supported.")
            }
            device.unlockForConfiguration()
        } catch let error {
            print("Could not lock device for configuration: \(error)")
        }
    }

    func changeISO(device: AVCaptureDevice, isoValue: Double, completion: (String)->()) {
        do {
            try device.lockForConfiguration()
            device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: Float(isoValue), completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("YPCameraVC -> Can't set ISO for some reason.")
        }

        completion(String(Int(isoValue)))
    }

    func enableAutoISO(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            } else {
                print("Exposure mode auto is not supported.")
            }
            device.unlockForConfiguration()
        } catch let error {
            print("Could not lock device for configuration: \(error)")
        }
    }

    func changeFocus(device: AVCaptureDevice, focusValue: Double, completion: (String)->()) {
        do {
            try device.lockForConfiguration()
            device.setFocusModeLocked(lensPosition: Float(focusValue), completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("YPCameraVC -> Can't set focus for some reason.")
        }

        completion(String(format: "%.2f", Double(focusValue)))
    }

    func enableAutoFocus(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) {
                device.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            } else {
                print("Focus mode auto is not supported.")
            }
            device.unlockForConfiguration()
        } catch let error {
            print("Could not lock device for configuration: \(error)")
        }
    }

    private let kExposureDurationPower = 5.0 // Higher numbers will give the slider more sensitivity at shorter durations
    private let kExposureMinimumDuration = 1.0/1000 // Limit exposure duration to a useful range

    func changeExposureDuration(device: AVCaptureDevice, durationValue: Double, completion: (String)->()) {
        let p = pow(durationValue, kExposureDurationPower) // Apply power function to expand slider's low-end range
        let minDurationSeconds = max(CMTimeGetSeconds(device.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxDurationSeconds = CMTimeGetSeconds(device.activeFormat.maxExposureDuration)
        let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration

        do {
            try device.lockForConfiguration()
                    device.setExposureModeCustom(duration: CMTimeMakeWithSeconds(newDurationSeconds, preferredTimescale: 1000*1000*1000), iso: AVCaptureDevice.currentISO, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("YPCameraVC -> Can't set exposure duration for some reason.")
        }

        if newDurationSeconds < 1 {
            let digits = max(0, 2 + Int(floor(log10(newDurationSeconds))))
            completion(String(format: "1/%.*f", digits, 1/newDurationSeconds))
        } else {
            completion(String(format: "%.2f", newDurationSeconds))
        }
    }

    func enableAutoExposure(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            } else {
                print("Exposure mode auto is not supported.")
            }
            device.unlockForConfiguration()
        } catch let error {
            print("Could not lock device for configuration: \(error)")
        }
    }


    func OIS() {
//        guard let photoOutput = self.photoOutput else {
//            return nil
//        }
//        let photoOutput: AVCapturePhotoOutputType
//
//        let lensStabilizationEnabled = true
//        var photoSettings: AVCapturePhotoSettings? = nil
//
//        if lensStabilizationEnabled && photoOutput.isLensStabilizationDuringBracketedCaptureSupported {
//            let bracketedSettings: [AVCaptureBracketedStillImageSettings]
//            if self.videoDevice?.exposureMode == .custom {
//                bracketedSettings = [AVCaptureManualExposureBracketedStillImageSettings.manualExposureSettings(exposureDuration: AVCaptureDevice.currentExposureDuration, iso: AVCaptureDevice.currentISO)]
//            } else {
//                bracketedSettings = [AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: AVCaptureDevice.currentExposureTargetBias)]
//            }
//
//            photoSettings = AVCapturePhotoBracketSettings(rawPixelFormatType: 0, processedFormat: [AVVideoCodecKey: AVVideoCodecJPEG], bracketedSettings: bracketedSettings)
//
//            (photoSettings as! AVCapturePhotoBracketSettings).isLensStabilizationEnabled = true
//        } else {
//            photoSettings = AVCapturePhotoSettings()
//        }

    }


}
