//
//  YPCameraVC.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

protocol CameraDelegate: class {
    func didChangeRatio(buttonTag: Int)
}

public class YPCameraVC: UIViewController, UIGestureRecognizerDelegate, YPPermissionCheckable, UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView == v.pickerView ? 101 : 2
    }

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView == v.pickerView ? 21 : 100
    }

    let selectionLineTagNumber = 37

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {

        pickerView.subviews[1].isHidden = true
        pickerView.subviews[2].isHidden = true

        if pickerView == v.pickerView {
            let selectionLine = UIView(frame: CGRect(x: 0, y: pickerView.frame.width / 2 - 1, width: 40, height: 3))
            selectionLine.tag = selectionLineTagNumber
            selectionLine.backgroundColor = UIColor(red: 245/255, green: 89/255, blue: 61/255, alpha: 1.0)

            for subview in pickerView.subviews {
                if subview.tag == selectionLineTagNumber {
                    subview.removeFromSuperview()
                }
            }
            pickerView.addSubview(selectionLine)

            let view = UIView(frame: CGRect(x: 10, y: 10, width: 15, height: 2))

            let grayColor = UIColor(red: 151/255, green: 151/255, blue: 151/255, alpha: 1.0)

            view.backgroundColor = (row % 5 == 0) ? .white : grayColor

            return view
        } else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

            let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
            label.font = UIFont.systemFont(ofSize: 12)
            label.textAlignment = .center
            label.textColor = .white
            label.text = row == 0 ? "TINT" : "TEMPERATURE"

            view.addSubview(label)

            view.transform = CGAffineTransform(rotationAngle: -90 * (.pi/180))

            return view
        }

    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == v.pickerView {
            guard let device = photoCapture.device else {
                return
            }

            var selectedValue: Double

            switch self.currentPickerType {
            case .iso:
                let stepSize = (device.activeFormat.maxISO - device.activeFormat.minISO)/100
                selectedValue = Double(device.activeFormat.minISO) + Double(stepSize)*Double(row)
                whiteBalanceHelper.changeISO(device: device, isoValue: selectedValue) { [weak self] valueLabel in
                    self?.v.pickerValueLabel.text = valueLabel
                }
                previousISORow = row
            case .focus:
                let stepSize = 0.01
                selectedValue = stepSize*Double(row)
                whiteBalanceHelper.changeFocus(device: device, focusValue: selectedValue) { [weak self] valueLabel in
                    self?.v.pickerValueLabel.text = valueLabel
                }
                previousFocusRow = row
            case .exposure:
                let stepSize = 0.01
                selectedValue = stepSize*Double(row)
                whiteBalanceHelper.changeExposureDuration(device: device, durationValue: selectedValue) { [weak self] valueLabel in
                    self?.v.pickerValueLabel.text = valueLabel
                }
                previousExposureRow = row
            case .temperature:
                let stepSize = 50
                let minValue = 3000
                selectedValue = Double(minValue) + Double(stepSize)*Double(row)
                whiteBalanceHelper.changeTemperature(device: device, temperature: Double(selectedValue)) { [weak self] currentValue in
                    self?.v.pickerValueLabel.text = String(currentValue)
                }
                previousTemperatureRow = row
            case .tint:
                let stepSize = 3
                let minValue = -150
                selectedValue = Double(minValue) + Double(stepSize)*Double(row)
                whiteBalanceHelper.changeTint(device: device, tint: Double(selectedValue)) { [weak self] currentValue in
                    self?.v.pickerValueLabel.text = String(currentValue)
                }
                previousTintRow = row
            default:
                return
            }

            print("selected: \(selectedValue)")

        } else {
            for row in 0...pickerView.numberOfRows(inComponent: component) {
                colorSelectedView(row: row, inComponent: component, selected: false)
            }
            colorSelectedView(row: row, inComponent: component, selected: true)

            row == 0 ? tintMode(enabled: true) : temperatureMode(enabled: true)
        }
    }

    func colorSelectedView(row: Int, inComponent component: Int, selected: Bool) {
        guard let view = v.whiteBalancePickerView.view(forRow: row, forComponent: component) else {
            return
        }

        for subview in view.subviews {
            if let label = subview as? UILabel {
                label.textColor = selected ? UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1.0) : .white
            }
        }
    }

    func settingsMode(enabled: Bool) {
        self.v.settingsButton.setImage(enabled ? YPConfig.icons.settingsOnIcon : YPConfig.icons.settingsOffIcon, for: .normal)
        self.v.shotButton.isHidden = enabled
        self.v.flipButton.isHidden = enabled

        self.v.doneButton.isHidden = !enabled
        self.v.isoButton.isHidden = !enabled
        self.v.focusButton.isHidden = !enabled
        self.v.exposureButton.isHidden = !enabled
        self.v.whiteBalanceButton.isHidden = !enabled
        if !enabled {
            setupPicker(type: .none)
            self.v.isoButton.tintColor = .white
            self.v.focusButton.tintColor = .white
            self.v.exposureButton.tintColor = .white
            self.v.whiteBalanceButton.tintColor = .white
        }
    }

    enum PickerSettingType {
        case none
        case iso
        case focus
        case exposure
        case temperature
        case tint
    }

    var previousISORow: Int = -1
    var previousFocusRow: Int = -1
    var previousExposureRow: Int = -1
    var previousTemperatureRow: Int = -1
    var previousTintRow: Int = -1

    private func autoEnabeldForType(type: PickerSettingType) -> Bool {
        switch type {
        case .iso:
            return autoISO
        case .focus:
            return autoFocus
        case .exposure:
            return autoExposure
        case .temperature:
            return autoWhiteBalance
        case .tint:
            return autoWhiteBalance
        default:
            return false
        }
    }

    private func valueLabelForType(type: PickerSettingType) -> String {
        guard let device = photoCapture.device else {
            return ""
        }

        switch type {
        case .iso:
            return String(Int(device.iso))
        case .focus:
            return String(format: "%.2f", device.lensPosition)
        case .exposure:
            return durationString(device: device)
        case .temperature:
            return temperatureString(device: device)
        case .tint:
            return tintString(device: device)
        default:
            return ""
        }
    }

    private func temperatureString(device: AVCaptureDevice) -> String {
        let temperatureAndTint = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
        return String(Int(temperatureAndTint.temperature))
    }

    private func tintString(device: AVCaptureDevice) -> String {
        let temperatureAndTint = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
        return String(Int(temperatureAndTint.tint))
    }

    private let kExposureDurationPower = 5.0 // Higher numbers will give the slider more sensitivity at shorter durations
    private let kExposureMinimumDuration = 1.0/1000 // Limit exposure duration to a useful range

    private func durationString(device: AVCaptureDevice) -> String {
        let newDurationSeconds = CMTimeGetSeconds(device.exposureDuration)

        if newDurationSeconds < 1 {
            let digits = max(0, 2 + Int(floor(log10(newDurationSeconds))))
            return String(format: "1/%.*f", digits, 1/newDurationSeconds)
        } else {
            return String(format: "%.2f", newDurationSeconds)
        }
    }

    func setupPicker(type: PickerSettingType) {
        guard let device = photoCapture.device else {
            return
        }

        currentPickerType = type
        self.v.pickerView.frame = CGRect(x: 95 / 2, y: self.v.pickerBackground.frame.height - 40, width: self.v.pickerBackground.frame.width - 95, height: 40)
        self.v.whiteBalancePickerView.frame = CGRect(x: 95 / 2, y: 0, width: self.v.pickerBackground.frame.width - 95, height: 30)
        self.v.autoButton.frame = CGRect(x: self.v.pickerBackground.frame.width - 28 - 16, y: self.v.pickerBackground.frame.height - 52, width: 28, height: 52)
        self.v.pickerValueLabel.frame = CGRect(x: 18, y: 0, width: 37, height: self.v.pickerBackground.frame.height)

        self.v.pickerBackground.isHidden = (type == .none)
        self.v.pickerView.isHidden = (type == .none) || autoEnabeldForType(type: type)
        self.v.whiteBalancePickerView.isHidden = !(type == .temperature || type == .tint) || autoEnabeldForType(type: type)
        self.v.autoButton.isHidden = (type == .none)
        self.v.pickerValueLabel.isHidden = (type == .none) || autoEnabeldForType(type: type)
        self.v.pickerValueLabel.text = valueLabelForType(type: type)

        switch type {
        case .iso:
            if previousISORow == -1 {
                let stepSize = (device.activeFormat.maxISO - device.activeFormat.minISO)/100
                let row = Int(round((device.iso - device.activeFormat.minISO)/stepSize))
                self.v.pickerView.selectRow(row, inComponent: 0, animated: false)
            } else {
                self.v.pickerView.selectRow(previousISORow, inComponent: 0, animated: false)
            }
        case .focus:
            if previousFocusRow == -1 {
                let stepSize = 0.01
                let row = Int(round(Double(device.lensPosition)/stepSize))
                self.v.pickerView.selectRow(row, inComponent: 0, animated: false)
            } else {
                self.v.pickerView.selectRow(previousFocusRow, inComponent: 0, animated: false)
            }
        case .exposure:
            if previousExposureRow == -1 {
                let newPower: Double = 1/kExposureDurationPower
                let currentDurationSeconds = CMTimeGetSeconds(device.exposureDuration)
                let minDurationSeconds = max(CMTimeGetSeconds(device.activeFormat.minExposureDuration), kExposureMinimumDuration)
                let maxDurationSeconds = CMTimeGetSeconds(device.activeFormat.maxExposureDuration)
                let currentDuration = (currentDurationSeconds - minDurationSeconds) / (maxDurationSeconds - minDurationSeconds)
                let selectedValue = pow(currentDuration, newPower)

                let stepSize = 0.01
                let row = Int(round(selectedValue/stepSize))
                self.v.pickerView.selectRow(row, inComponent: 0, animated: false)
            } else {
                self.v.pickerView.selectRow(previousExposureRow, inComponent: 0, animated: false)
            }
        case .temperature:
            if previousTemperatureRow == -1 {
                let stepSize = Double(50)
                let minValue = Double(3000)
                let temperature = Double(device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).temperature)
                let row = Int(round((temperature - minValue)/stepSize))
                self.v.pickerView.selectRow(row, inComponent: 0, animated: false)
            } else {
                self.v.pickerView.selectRow(previousTemperatureRow, inComponent: 0, animated: false)
            }
        case .tint:
            if previousTintRow == -1 {
                let stepSize = Double(3)
                let minValue = Double(-150)
                let tint = Double(device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).tint)
                let row = Int(round((tint - minValue)/stepSize))
                self.v.pickerView.selectRow(row, inComponent: 0, animated: false)
            } else {
                self.v.pickerView.selectRow(previousTintRow, inComponent: 0, animated: false)
            }
        default:
            return
        }
    }

    var currentPickerType: PickerSettingType = .none
    var autoISO = false
    var autoFocus = false
    var autoExposure = false
    var autoWhiteBalance = false

    func isoMode(enabled: Bool) {
        self.v.isoButton.tintColor = enabled ? YPConfig.colors.yellowTintColor : .white
        if enabled {
            setupPicker(type: .iso)
            self.v.autoButton.isSelected = autoISO
            self.v.pickerView.isUserInteractionEnabled = !autoISO
        }
    }

    func focusMode(enabled: Bool) {
        self.v.focusButton.tintColor = enabled ? YPConfig.colors.yellowTintColor : .white
        if enabled {
            setupPicker(type: .focus)
            self.v.autoButton.isSelected = autoFocus
            self.v.pickerView.isUserInteractionEnabled = !autoFocus
        }
    }

    func exposureMode(enabled: Bool) {
        self.v.exposureButton.tintColor = enabled ? YPConfig.colors.yellowTintColor : .white
        if enabled {
            setupPicker(type: .exposure)
            self.v.autoButton.isSelected = autoExposure
            self.v.pickerView.isUserInteractionEnabled = !autoExposure
        }
    }

    func whiteBalanceMode(enabled: Bool) {
        self.v.whiteBalanceButton.tintColor = enabled ? YPConfig.colors.yellowTintColor : .white
        temperatureMode(enabled: enabled)
        self.v.whiteBalancePickerView.selectRow(1, inComponent: 0, animated: false)
    }

    func temperatureMode(enabled: Bool) {
        if enabled {
            setupPicker(type: .temperature)
            self.v.autoButton.isSelected = autoWhiteBalance
        }
    }

    func tintMode(enabled: Bool) {
        if enabled {
            setupPicker(type: .tint)
            self.v.autoButton.isSelected = autoWhiteBalance
        }
    }

    public var didCapturePhoto: ((UIImage) -> Void)?
    let photoCapture = newPhotoCapture()
    let v: YPCameraView!
    let whiteBalanceHelper = YPCameraSettingsHelper()
    override public func loadView() { view = v }

    public required init() {
        self.v = YPCameraView(overlayView: YPConfig.overlayView)
        super.init(nibName: nil, bundle: nil)
        title = YPConfig.wordings.cameraTitle
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var pinchRecognizer: UIPinchGestureRecognizer?

    override public func viewDidLoad() {
        super.viewDidLoad()
        v.flashButton.isHidden = true
        v.flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        for button in self.v.ratioButtonsStackView.arrangedSubviews {
            if let button = button as? UIButton {
                button.addTarget(self, action: #selector(ratioSelected(sender:)), for: .touchUpInside)
            }
        }
        v.OISSwitch.addTarget(self, action: #selector(OISSwitchChanged), for: .valueChanged)
        v.gridSwitch.addTarget(self, action: #selector(gridSwitchChanged), for: .valueChanged)
        v.settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        v.isoButton.addTarget(self, action: #selector(isoButtonTapped), for: .touchUpInside)
        v.focusButton.addTarget(self, action: #selector(focusButtonTapped), for: .touchUpInside)
        v.exposureButton.addTarget(self, action: #selector(exposureButtonTapped), for: .touchUpInside)
        v.whiteBalanceButton.addTarget(self, action: #selector(whiteBalanceButtonTapped), for: .touchUpInside)
        v.pickerView.dataSource = self
        v.pickerView.delegate = self
        v.whiteBalancePickerView.dataSource = self
        v.whiteBalancePickerView.delegate = self
        v.doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        v.autoButton.addTarget(self, action: #selector(autoButtonTapped), for: .touchUpInside)
        v.ratioButton.addTarget(self, action: #selector(ratioButtonTapped), for: .touchUpInside)

        // Focus
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.focusTapped(_:)))
        tapRecognizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)

        // Pinch
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(_:)))
        if let pinchRecognizer = pinchRecognizer {
            pinchRecognizer.delegate = self
            v.previewViewContainer.addGestureRecognizer(pinchRecognizer)
        }

    }

    func start(withGrid: Bool? = false) {
        doAfterPermissionCheck { [weak self] in
            guard let strongSelf = self else {
                return
            }
            self?.photoCapture.start(with: strongSelf.v.previewViewContainer, completion: {
                DispatchQueue.main.async {
                    self?.refreshFlashButton()
                    self?.v.overlay?.isHidden = !(withGrid ?? false)
                }
            })
        }
    }

    @objc
    func focusTapped(_ recognizer: UITapGestureRecognizer) {
        doAfterPermissionCheck { [weak self] in
            self?.focus(recognizer: recognizer)
        }
    }
    
    func focus(recognizer: UITapGestureRecognizer) {

        let point = recognizer.location(in: v.previewViewContainer)
        
        // Focus the capture
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x: point.x/viewsize.width, y: point.y/viewsize.height)
        photoCapture.focus(on: newPoint)
        
        // Animate focus view
        v.focusView.center = point
        YPHelper.configureFocusView(v.focusView)
        v.addSubview(v.focusView)
        YPHelper.animateFocusView(v.focusView)
    }

    var pivotPinchScale: CGFloat = 1.0

    @objc
    func pinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let device = photoCapture.device else {
            return
        }

        do {
            try device.lockForConfiguration()
            switch recognizer.state {
            case .began:
                self.pivotPinchScale = device.videoZoomFactor
            case .changed:
                var factor = self.pivotPinchScale * recognizer.scale
                factor = max(1, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = factor
            default:
                break
            }
            device.unlockForConfiguration()
        } catch {
            print("YPCameraVC -> Can't zoom preview for some reason.")
        }
    }
        
    func stopCamera() {
        photoCapture.stopCamera()
    }
    
    @objc
    func flipButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.photoCapture.flipCamera {
                self?.refreshFlashButton()
            }
        }
    }

    var currentRatioTag = YPConfig.initialSelectedRatioButtonTag
    weak var delegate: CameraDelegate?

    @objc
    func ratioSelected(sender: UIButton) {
        currentRatioTag = sender.tag
        delegate?.didChangeRatio(buttonTag: sender.tag)

        for button in self.v.ratioButtonsStackView.arrangedSubviews {
            for subview in button.subviews {
                if let image = subview as? UIImageView {
                    image.tintColor = (button.tag == sender.tag) ? YPConfig.colors.yellowTintColor : .white
                } else if let label = subview as? UILabel {
                    label.textColor = (button.tag == sender.tag) ? YPConfig.colors.yellowTintColor : .white
                }
            }
        }

        let gridShowed = !(self.v.overlay?.isHidden ?? true)
        stopCamera()
        self.v.overlay?.isHidden = true
        self.v.ratioSelected(senderTag: sender.tag)
        start(withGrid: gridShowed)
    }

    @objc
    func OISSwitchChanged() {
        print("OIS: \(self.v.OISSwitch.isOn)")
    }

    @objc
    func gridSwitchChanged() {
        if let overlay = self.v.overlay {
            overlay.isHidden = !overlay.isHidden
            if let pinchRecognizer = pinchRecognizer {
                if overlay.isHidden {
                    overlay.removeGestureRecognizer(pinchRecognizer)
                    self.v.previewViewContainer.addGestureRecognizer(pinchRecognizer)
                } else {
                    self.v.previewViewContainer.removeGestureRecognizer(pinchRecognizer)
                    overlay.addGestureRecognizer(pinchRecognizer)
                }
            }
        }
    }

    @objc
    func settingsButtonTapped() {
        self.settingsMode(enabled: true)
    }

    @objc
    func doneButtonTapped() {
        self.settingsMode(enabled: false)
    }

    @objc
    func autoButtonTapped() {
        guard let device = photoCapture.device else {
            return
        }

        self.v.autoButton.isSelected = !self.v.autoButton.isSelected
        self.v.pickerView.isUserInteractionEnabled = !self.v.autoButton.isSelected

        switch self.currentPickerType {
        case .iso:
            self.autoISO = self.v.autoButton.isSelected
            self.autoExposure = self.v.autoButton.isSelected
            self.v.pickerView.isHidden = self.autoISO
            self.v.pickerValueLabel.isHidden = self.autoISO
            if self.autoISO {
                whiteBalanceHelper.enableAutoISO(device: device)
            }
        case .focus:
            self.autoFocus = self.v.autoButton.isSelected
            self.v.pickerView.isHidden = self.autoFocus
            self.v.pickerValueLabel.isHidden = self.autoFocus
            if self.autoFocus {
                whiteBalanceHelper.enableAutoFocus(device: device)
            }
        case .exposure:
            self.autoExposure = self.v.autoButton.isSelected
            self.autoISO = self.v.autoButton.isSelected
            self.v.pickerView.isHidden = self.autoExposure
            self.v.pickerValueLabel.isHidden = self.autoExposure
            if self.autoExposure {
                whiteBalanceHelper.enableAutoExposure(device: device)
            }
        case .temperature:
            self.autoWhiteBalance = self.v.autoButton.isSelected
            self.v.pickerView.isHidden = self.autoWhiteBalance
            self.v.pickerValueLabel.isHidden = self.autoWhiteBalance
            self.v.whiteBalancePickerView.isHidden = self.autoWhiteBalance
            if self.autoWhiteBalance {
                whiteBalanceHelper.enableAutoWhiteBalance(device: device)
            }
        case .tint:
            self.autoWhiteBalance = self.v.autoButton.isSelected
            self.v.pickerView.isHidden = self.autoWhiteBalance
            self.v.pickerValueLabel.isHidden = self.autoWhiteBalance
            self.v.whiteBalancePickerView.isHidden = self.autoWhiteBalance
            if self.autoWhiteBalance {
                whiteBalanceHelper.enableAutoWhiteBalance(device: device)
            }
        default:
            return
        }
    }

    @objc
    func ratioButtonTapped() {
        self.showHideRatioView()
    }

    func showHideRatioView() {
        self.v.ratioBackground.isHidden = !self.v.ratioBackground.isHidden
        self.v.ratioLabel.frame = CGRect(x: self.v.ratioBackground.frame.width - 60, y: 15, width: 50, height: 150)
        self.v.ratioSeparator.frame = CGRect(x: self.v.ratioLabel.frame.origin.x, y: 0, width: 1, height: self.v.ratioBackground.frame.height)
        self.v.ratioButtonsStackView.frame = CGRect(x: self.v.ratioSeparator.frame.origin.x - 200, y: 0, width: 200, height: 200)
        self.v.OISSeparator.frame = CGRect(x: self.v.ratioButtonsStackView.frame.origin.x, y: 0, width: 1, height: self.v.ratioBackground.frame.height)
        self.v.OISLabel.frame = CGRect(x: self.v.OISSeparator.frame.origin.x - 50, y: 15, width: 50, height: 150)
        self.v.OISSwitch.frame = CGRect(x: self.v.OISSeparator.frame.origin.x - 60, y: 80, width: 50, height: 150)
        self.v.gridSeparator.frame = CGRect(x: self.v.OISLabel.frame.origin.x, y: 0, width: 1, height: self.v.ratioBackground.frame.height)
        self.v.gridLabel.frame = CGRect(x: self.v.gridSeparator.frame.origin.x - 50, y: 15, width: 50, height: 150)
        self.v.gridSwitch.frame = CGRect(x: self.v.gridSeparator.frame.origin.x - 60, y: 80, width: 50, height: 150)
        self.v.bottomSeparator.frame = CGRect(x: self.v.gridLabel.frame.origin.x, y: 0, width: 1, height: self.v.ratioBackground.frame.height)
    }

    @objc
    func isoButtonTapped() {
        self.isoMode(enabled: true)
        self.focusMode(enabled: false)
        self.exposureMode(enabled: false)
        self.whiteBalanceMode(enabled: false)
    }

    @objc
    func focusButtonTapped() {
        self.focusMode(enabled: true)
        self.isoMode(enabled: false)
        self.exposureMode(enabled: false)
        self.whiteBalanceMode(enabled: false)
    }

    @objc
    func exposureButtonTapped() {
        self.exposureMode(enabled: true)
        self.isoMode(enabled: false)
        self.focusMode(enabled: false)
        self.whiteBalanceMode(enabled: false)
    }

    @objc
    func whiteBalanceButtonTapped() {
        self.whiteBalanceMode(enabled: true)
        self.isoMode(enabled: false)
        self.focusMode(enabled: false)
        self.exposureMode(enabled: false)
    }
    
    @objc
    func shotButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.shoot()
        }
    }
    
    func shoot() {
        // Prevent from tapping multiple times in a row
        // causing a crash
        v.shotButton.isEnabled = false
        
        photoCapture.shoot { imageData in
            
            guard let shotImage = UIImage(data: imageData) else {
                return
            }
            
            self.photoCapture.stopCamera()
            
            var image = shotImage
            // Crop the image if the output needs to be square.
            if self.currentRatioTag == 3 {
                image = self.cropImageToSquare(image)
            }

//            image = image.resizedImageIfNeeded()

            // Flip image if taken form the front camera.
            if let device = self.photoCapture.device, device.position == .front {

                let isVertical = image.size.height > image.size.width
                if !isVertical {
                    image = image.withHorizontallyFlippedOrientation()
                } else {
                    image = self.flipImage(image: image)
                }
                DispatchQueue.main.async {
                    self.didCapturePhoto?(image)
                }
            } else {
                let cropRect = self.cropRectToPreview(for: image)
                let finalCgImage = image.cgImage?.cropping(to: cropRect)!

                image = UIImage(cgImage: finalCgImage!, scale: 1.0, orientation: image.imageOrientation)

                DispatchQueue.main.async {
                    self.didCapturePhoto?(image)
                }
            }
        }
    }

    func cropRectToPreview(for image: UIImage) -> CGRect {
        let visibleLayerFrame = photoCapture.previewView.frame

        var metaRect = CGRect(x: 0, y: 0, width: 1, height: 1)

        if currentRatioTag != 3 {
            metaRect = photoCapture.videoLayer.metadataOutputRectConverted(fromLayerRect: visibleLayerFrame)
        }

        var originalSize = image.size
        if (image.imageOrientation == .left || image.imageOrientation == .right) {
            // For portrait images, swap the size of the
            // image because here the output image is actually rotated
            // relative to what you see on screen.
            originalSize = CGSize(width: image.size.height, height: image.size.width)
        }

        var marginToAdd: CGFloat = 0
        if currentRatioTag == 1 {
            marginToAdd = 400
        } else if currentRatioTag == 2 {
            marginToAdd = 200
        }
        
        var cropRect = CGRect()
        cropRect.origin.x = metaRect.origin.y * originalSize.height
        cropRect.origin.y = metaRect.origin.x * originalSize.width - marginToAdd
        cropRect.size.width = metaRect.size.width * originalSize.width
        cropRect.size.height = metaRect.size.height * originalSize.height

        let integral = cropRect.integral

        return integral
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        var imageWidth = image.size.width
        var imageHeight = image.size.height
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            // Swap width and height if orientation is landscape
            imageWidth = image.size.height
            imageHeight = image.size.width
        default:
            break
        }
        
        // The center coordinate along Y axis
        let rcy = imageHeight * 0.5
        let rect = CGRect(x: rcy - imageWidth * 0.5, y: 0, width: imageWidth, height: imageWidth)
        let imageRef = image.cgImage?.cropping(to: rect)
        return UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
    }
    
    // Used when image is taken from the front camera.
    func flipImage(image: UIImage!) -> UIImage! {
        let imageSize: CGSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.rotate(by: CGFloat(Double.pi/2.0))
        ctx.translateBy(x: 0, y: -imageSize.width)
        ctx.scaleBy(x: imageSize.height/imageSize.width, y: imageSize.width/imageSize.height)
        ctx.draw(image.cgImage!, in: CGRect(x: 0.0,
                                            y: 0.0,
                                            width: imageSize.width,
                                            height: imageSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @objc
    func flashButtonTapped() {
        photoCapture.tryToggleFlash()
        refreshFlashButton()
    }
    
    func refreshFlashButton() {
        let flashImage = photoCapture.currentFlashMode.flashImage()
        v.flashButton.setImage(flashImage, for: .normal)
        v.flashButton.isHidden = !photoCapture.hasFlash
    }
}

