//
//  RootViewCell.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit

class RootViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func showSample(_ sample: Sample) {
        titleLabel.text  = sample.title
        detailLabel.text = sample.detail
    }
}
