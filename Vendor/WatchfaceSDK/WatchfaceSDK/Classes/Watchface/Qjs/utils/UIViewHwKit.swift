//
//  UIViewHwKit.swift
//  HuaWo_iOS_SDKDemo
//
//  Created by HuaWo on 2024/8/6.
//

import UIKit
 
public extension UIView {
    func asImage() -> UIImage? {
        // 开始图形上下文
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() } // 确保上下文能被释放
        // 将view的layer渲染到图形上下文中
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            // 从图形上下文获取图片
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
}

