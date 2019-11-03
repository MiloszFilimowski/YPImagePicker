//
//  YPCameraView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia

class YPCameraView: UIView, UIGestureRecognizerDelegate {
    
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    let previewHelperViewContainer = UIView()
    let previewViewContainer = UIView()
    let leftBarBackground = UIView()
    let backButton = UIButton()
    let flipButton = UIButton()
    let shotButton = UIButton()
    let flashButton = UIButton()
    let ratioButton = UIButton()
    let settingsButton = UIButton()
    let pickerBackground = UIView()
    let autoButton = UIButton()
    let pickerValueLabel = UILabel()
    let settingsBarBackground = UIView()
    let doneButton = UIButton()
    let isoButton = UIButton()
    let focusButton = UIButton()
    let exposureButton = UIButton()
    let whiteBalanceButton = UIButton()
    let pickerView = UIPickerView()
    let whiteBalancePickerView = UIPickerView()
    let timeElapsedLabel = UILabel()
    let progressBar = UIProgressView()
    var overlay: UIView?
    let ratioBackground = UIView()
    let ratioLabel = UILabel()
    let ratioSeparator = UIView()
    let ratioButtonsStackView = UIStackView()
    let OISSeparator = UIView()
    let OISLabel = UILabel()
    let OISSwitch = UISwitch()
    let gridSeparator = UIView()
    let gridLabel = UILabel()
    let gridSwitch = UISwitch()
    let bottomSeparator = UIView()

    var previewTopContraint: NSLayoutConstraint?
    var previewBottomContraint: NSLayoutConstraint?
    var preview169WidthContraint: NSLayoutConstraint?
    var preview32WidthContraint: NSLayoutConstraint?
    var preview43HeightContraint: NSLayoutConstraint?
    var preview11HeightContraint: NSLayoutConstraint?
    var previewFullWidthContraint: NSLayoutConstraint?
    var previewCenterYContraint: NSLayoutConstraint?

    convenience init(overlayView: UIView? = nil) {
        self.init(frame: .zero)

        self.overlay = overlayView
        self.overlay?.isHidden = !YPConfig.isGridOn
        self.gridSwitch.isOn = YPConfig.isGridOn
        self.OISSwitch.isOn = YPConfig.isOISOn

        if let overlayView = overlayView {
            // View Hierarchy
            sv(
                previewHelperViewContainer,
                previewViewContainer,
                overlayView,
                progressBar,
                timeElapsedLabel,
                leftBarBackground,
                backButton,
                flashButton,
                ratioButton,
                flipButton,
                pickerBackground,
                settingsBarBackground,
                flipButton,
                settingsButton,
                doneButton,
                isoButton,
                focusButton,
                exposureButton,
                whiteBalanceButton,
                shotButton,
                ratioBackground
            )
        } else {
            // View Hierarchy
            sv(
                previewHelperViewContainer,
                previewViewContainer,
                progressBar,
                timeElapsedLabel,
                leftBarBackground,
                backButton,
                flashButton,
                ratioButton,
                pickerBackground,
                settingsBarBackground,
                flipButton,
                settingsButton,
                doneButton,
                isoButton,
                focusButton,
                exposureButton,
                whiteBalanceButton,
                shotButton,
                ratioBackground
            )
        }

        pickerBackground.addSubview(pickerView)
        pickerBackground.addSubview(whiteBalancePickerView)
        pickerBackground.addSubview(autoButton)
        pickerBackground.addSubview(pickerValueLabel)

        // Layout
        let isIphone4 = UIScreen.main.bounds.height == 480
        let isIphoneX = UIScreen.main.bounds.height > 800
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
//        layout(
//            0,
//            |-sideMargin-previewViewContainer-sideMargin-|,
//            0
//        )

        leftBarBackground.Right == Right
        leftBarBackground.Left == Left
        leftBarBackground.Top == Top + (isIphoneX ? 30 : 0)
        leftBarBackground.height(44)

        previewHelperViewContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        previewHelperViewContainer.topAnchor.constraint(equalTo: leftBarBackground.bottomAnchor).isActive = true
        previewHelperViewContainer.bottomAnchor.constraint(equalTo: settingsBarBackground.topAnchor).isActive = true
        previewHelperViewContainer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        previewHelperViewContainer.backgroundColor = .black

        previewViewContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        previewTopContraint = previewViewContainer.topAnchor.constraint(equalTo: leftBarBackground.bottomAnchor)
        previewBottomContraint = previewViewContainer.bottomAnchor.constraint(equalTo: settingsBarBackground.topAnchor)
        preview169WidthContraint = previewViewContainer.widthAnchor.constraint(equalTo: previewViewContainer.heightAnchor, multiplier: 9/16)
        preview32WidthContraint = previewViewContainer.widthAnchor.constraint(equalTo: previewViewContainer.heightAnchor, multiplier: 2/3)
        previewFullWidthContraint = previewViewContainer.widthAnchor.constraint(equalTo: widthAnchor)
        preview43HeightContraint = previewViewContainer.heightAnchor.constraint(equalTo: previewViewContainer.widthAnchor, multiplier: 4/3)
        preview11HeightContraint = previewViewContainer.heightAnchor.constraint(equalTo: previewViewContainer.widthAnchor)
        previewCenterYContraint = previewViewContainer.centerYAnchor.constraint(equalTo: previewHelperViewContainer.centerYAnchor)

        switch YPConfig.initialSelectedRatioButtonTag {
        case 0:
            previewTopContraint?.isActive = true
            previewBottomContraint?.isActive = true
            preview169WidthContraint?.isActive = true
        case 1:
            previewFullWidthContraint?.isActive = true
            preview43HeightContraint?.isActive = true
            previewCenterYContraint?.isActive = true
        case 2:
            previewTopContraint?.isActive = true
            previewBottomContraint?.isActive = true
            preview32WidthContraint?.isActive = true
        case 3:
            previewCenterYContraint?.isActive = true
            previewFullWidthContraint?.isActive = true
            preview11HeightContraint?.isActive = true
        default:
            break;
        }

        progressBar.centerVertically()
        progressBar.centerHorizontally()

        overlayView?.followEdges(previewViewContainer)

        |-(15+sideMargin)-flashButton.size(80)
        flashButton.CenterY == leftBarBackground.CenterY

        |flashButton-(44)-ratioButton.size(80)
        ratioButton.CenterY == leftBarBackground.CenterY

        flipButton.size(44)-(20+sideMargin)-|
        flipButton.CenterY == shotButton.CenterY

        backButton.size(80)-(20+sideMargin)-|
        backButton.CenterY == leftBarBackground.CenterY

        timeElapsedLabel-(15+sideMargin)-|
        timeElapsedLabel.Top == previewViewContainer.Top + 15

        pickerBackground.Right == Right
        pickerBackground.Left == Left
        pickerBackground.Bottom == settingsButton.Top - 32
        pickerBackground.height(70)

        settingsBarBackground.Right == Right
        settingsBarBackground.Left == Left
        settingsBarBackground.Bottom == Bottom + (isIphoneX ? 35 : 0)
        settingsBarBackground.Top == settingsButton.Top - 32

        |-(20+sideMargin)-settingsButton.size(44)
        settingsButton.CenterY == shotButton.CenterY

        |settingsButton-(20)-whiteBalanceButton.size(44)
        whiteBalanceButton.CenterY == shotButton.CenterY

        whiteBalanceButton-(20)-exposureButton.size(44)
        exposureButton.CenterY == shotButton.CenterY

        exposureButton-(20)-focusButton.size(44)
        focusButton.CenterY == shotButton.CenterY

        focusButton-(20)-isoButton.size(44)
        isoButton.CenterY == shotButton.CenterY

        doneButton.size(44)-(10+sideMargin)-|
        doneButton.CenterY == shotButton.CenterY

        pickerView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        pickerValueLabel.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        whiteBalancePickerView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))

        shotButton.Bottom == Bottom - 20
        shotButton.centerHorizontally()

        ratioBackground.Left == Left
        ratioBackground.Right == Right
        ratioBackground.Top == leftBarBackground.Bottom
        ratioBackground.Bottom == settingsBarBackground.Top

        ratioBackground.addSubview(ratioLabel)
        ratioLabel.text = "ASPECT RATIO"
        ratioLabel.textColor = .white
        ratioLabel.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))

        ratioBackground.addSubview(ratioSeparator)
        ratioBackground.addSubview(ratioButtonsStackView)
        ratioBackground.addSubview(OISSeparator)
        ratioBackground.addSubview(OISLabel)
        OISLabel.text = "OIS"
        OISLabel.textColor = .white
        OISLabel.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        ratioBackground.addSubview(OISSwitch)
        OISSwitch.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        ratioBackground.addSubview(gridSeparator)
        ratioBackground.addSubview(gridLabel)
        gridLabel.text = "GRID"
        gridLabel.textColor = .white
        gridLabel.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        ratioBackground.addSubview(gridSwitch)
        gridSwitch.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        ratioBackground.addSubview(bottomSeparator)


        // Style
        backgroundColor = YPConfig.colors.photoVideoScreenBackground
        previewViewContainer.backgroundColor = .black
        timeElapsedLabel.style { l in
            l.textColor = .white
            l.text = "00:00"
            l.isHidden = true
            l.font = .monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.medium)
        }
        progressBar.style { p in
            p.trackTintColor = .clear
            p.tintColor = .red
        }

        leftBarBackground.backgroundColor = .black
        flashButton.setImage(YPConfig.icons.flashOffIcon, for: .normal)
        ratioButton.setImage(YPConfig.icons.ratioIcon, for: .normal)
        backButton.setImage(YPConfig.icons.arrowBackIcon, for: .normal)
        flipButton.setImage(YPConfig.icons.loopIcon, for: .normal)
        pickerBackground.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        settingsBarBackground.backgroundColor = .black
        settingsButton.setImage(YPConfig.icons.settingsOffIcon, for: .normal)
        doneButton.setImage(YPConfig.icons.doneIcon, for: .normal)
        doneButton.isHidden = true
        isoButton.setImage(YPConfig.icons.isoIcon.withRenderingMode(.alwaysTemplate), for: .normal)
        isoButton.tintColor = .white
        isoButton.isHidden = true
        focusButton.setImage(YPConfig.icons.focusIcon.withRenderingMode(.alwaysTemplate), for: .normal)
        focusButton.tintColor = .white
        focusButton.isHidden = true
        exposureButton.setImage(YPConfig.icons.exposureIcon.withRenderingMode(.alwaysTemplate), for: .normal)
        exposureButton.tintColor = .white
        exposureButton.isHidden = true
        whiteBalanceButton.setImage(YPConfig.icons.whiteBalanceIcon.withRenderingMode(.alwaysTemplate), for: .normal)
        whiteBalanceButton.tintColor = .white
        whiteBalanceButton.isHidden = true
        pickerBackground.isHidden = true
        pickerView.isHidden = true
        whiteBalancePickerView.isHidden = true
        autoButton.setImage(YPConfig.icons.autoOffIcon, for: .normal)
        autoButton.setImage(YPConfig.icons.autoOnIcon, for: .selected)
        pickerValueLabel.textColor = UIColor(red: 163/255, green: 163/255, blue: 163/255, alpha: 1.0)
        pickerValueLabel.textAlignment = .right
        shotButton.setImage(YPConfig.icons.capturePhotoImage, for: .normal)
        ratioBackground.backgroundColor = UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1.0)
        ratioBackground.isHidden = true
        ratioSeparator.backgroundColor = .black
        ratioButtonsStackView.axis = .horizontal
        ratioButtonsStackView.distribution = .fillEqually
        ratioSeparator.backgroundColor = .black

        for i in 0...3 {
            let button = UIButton()
            button.tag = i
            let buttonIcon = UIImageView()
            buttonIcon.tintColor = .white
            let buttonLabel = UILabel()
            buttonLabel.textColor = .white

            if i == YPConfig.initialSelectedRatioButtonTag {
                buttonIcon.tintColor = YPConfig.colors.yellowTintColor
                buttonLabel.textColor = YPConfig.colors.yellowTintColor
            }

            if i == 0 {
                buttonIcon.image = YPConfig.icons.rectangle2Icon.withRenderingMode(.alwaysTemplate)
                buttonLabel.text = "16 : 9"
            } else if i == 1 {
                buttonIcon.image = YPConfig.icons.rectangle1Icon.withRenderingMode(.alwaysTemplate)
                buttonLabel.text = "4 : 3"

            } else if i == 2 {
                buttonIcon.image = YPConfig.icons.rectangle1Icon.withRenderingMode(.alwaysTemplate)
                buttonLabel.text = "3 : 2"
            } else if i == 3 {
                buttonIcon.image = YPConfig.icons.squareIcon.withRenderingMode(.alwaysTemplate)
                buttonLabel.text = "1 : 1"
            }
            buttonIcon.frame = CGRect(x: 15, y: 15, width: 20, height: 20)
            buttonLabel.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
            buttonLabel.frame = CGRect(x: 0, y: 50, width: 50, height: 50)
            button.addSubview(buttonIcon)
            button.addSubview(buttonLabel)
            ratioButtonsStackView.addArrangedSubview(button)
        }

        OISSeparator.backgroundColor = .black
        gridSeparator.backgroundColor = .black
        bottomSeparator.backgroundColor = .black
    }

    func ratioSelected(senderTag: Int) {
        switch senderTag {
        case 0:
            print("16:9")
            previewFullWidthContraint?.isActive = false
            preview32WidthContraint?.isActive = false
            previewCenterYContraint?.isActive = false
            preview43HeightContraint?.isActive = false
            preview11HeightContraint?.isActive = false
            previewTopContraint?.isActive = true
            previewBottomContraint?.isActive = true
            preview169WidthContraint?.isActive = true

        case 1:
            print("4:3")
            preview169WidthContraint?.isActive = false
            preview32WidthContraint?.isActive = false
            previewTopContraint?.isActive = false
            previewBottomContraint?.isActive = false
            preview11HeightContraint?.isActive = false
            previewCenterYContraint?.isActive = true
            previewFullWidthContraint?.isActive = true
            preview43HeightContraint?.isActive = true
        case 2:
            print("3:2")
            previewFullWidthContraint?.isActive = false
            preview169WidthContraint?.isActive = false
            previewCenterYContraint?.isActive = false
            preview43HeightContraint?.isActive = false
            preview11HeightContraint?.isActive = false
            previewTopContraint?.isActive = true
            previewBottomContraint?.isActive = true
            preview32WidthContraint?.isActive = true
        case 3:
            print("1:1")
            preview169WidthContraint?.isActive = false
            preview32WidthContraint?.isActive = false
            preview43HeightContraint?.isActive = false
            previewTopContraint?.isActive = false
            previewBottomContraint?.isActive = false
            previewCenterYContraint?.isActive = true
            previewFullWidthContraint?.isActive = true
            preview11HeightContraint?.isActive = true
        default:
            break
        }
    }

}
