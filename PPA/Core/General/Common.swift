//
//  Common.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/13.
//

import UIKit

///主窗口
var kMainWindow: UIWindow {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        return windowScene.windows[0]
    }
    return (UIApplication.shared.delegate?.window)!!
}

///状态栏高度
var kStatusBarHeight: CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let height = windowScene.statusBarManager?.statusBarFrame.height {
        return height
    }
    return 0
}

///导航条高度
var kNavBarHeight: CGFloat {
    return kStatusBarHeight + 44
}

///下边距
var kBottomSafe: CGFloat {
    return kMainWindow.safeAreaInsets.bottom
}

var kMainScreen: UIScreen {
    return (UIApplication.shared.connectedScenes.first as! UIWindowScene).screen
}

///屏幕宽度
var kScreenWidth: CGFloat {
    return kMainScreen.bounds.width
}

///屏幕高度
var kScreenHeight: CGFloat {
    return kMainScreen.bounds.height
}

///屏幕适配
func kRealValue(_ value: CGFloat) -> CGFloat {
    return value / 375.0 * kScreenWidth
}

///当前显示的控制器
var kCurrentVC: UIViewController? {
    var result: UIViewController? = kMainWindow.rootViewController
    while true {
        if result?.presentedViewController != nil {
            result = result?.presentedViewController
        } else if result is UINavigationController {
            if let top = (result as? UINavigationController)?.topViewController {
                result = top
            }
        } else if result is UITabBarController {
            result = (result as? UITabBarController)?.selectedViewController
        } else {
            break
        }
    }
    return result
}
