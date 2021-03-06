//
//  ThemeViewController.swift
//  MarkLite
//
//  Created by zhubch on 2017/8/8.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit

class ThemeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let items = [Theme.white,.black,.blue,.purple,.red,.green]
    let table = UITableView(frame: CGRect(), style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "设置"
        
        table.rowHeight = 48
        table.delegate = self
        table.dataSource = self
        table.setSeparatorColor(.primary)
        view.addSubview(table)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        table.frame = self.view.bounds
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = items[indexPath.row].displayName
        cell.textLabel?.setTextColor(.primary)
        cell.textLabel?.font = UIFont.font(ofSize: 16)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        Configure.shared.theme.value = item
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
}
