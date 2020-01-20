//
//  TiffinTableViewCell.swift
//  Tiffin Tracker
//
//  Created by RG on 3/8/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit

class TiffinTableViewCell: UITableViewCell {

    @IBOutlet weak var tiffinNameLabel: UILabel!
    @IBOutlet weak var tiffinCostLabel: UILabel!
    @IBOutlet weak var tiffinBalanceLabel: UILabel!
    @IBOutlet weak var tiffinDaysLabel: UILabel!
    @IBOutlet weak var viewBG: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
