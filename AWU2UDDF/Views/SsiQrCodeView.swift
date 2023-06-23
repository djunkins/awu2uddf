//
//  SsiQrCodeView.swift
//  AWU2UDDF
//
//  Created by Alejandro Valenzuela Roca on 20/05/23.
//

import SwiftUI

struct SsiQrCodeView: View {
    var qrCode : UIImage?
    
    var body: some View {
        VStack{
            Text("Scan with your Dive Buddy's SSI App")
            
            Image(uiImage:generateQRCode(from: "hello")!)
        }
    }
    
    // Generate QR codes
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
}

struct SsiQrCodeView_Previews: PreviewProvider {
    static var previews: some View {
        SsiQrCodeView()
    }
    
    
    
}
