//
//  FilesViewController.swift
//  MarkLite
//
//  Created by zhubch on 2017/6/22.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import SwipeCellKit
import RxSwift

class FilesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 50
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    @IBOutlet weak var emptyView: UIView!

    var selectedIndexPath: IndexPath?

    fileprivate var childrens = [File]()
    
    var root: File? {
        didSet {
            if root == nil {
                childrens = []
            } else {
                childrens = root!.children.sorted{$0.0.modifyDate < $0.1.modifyDate}
            }
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }

    let disposeBag = DisposeBag()
    
    let titleTextField = UITextField(x: 0, y: 0, w: 100, h: 30)
    
    let titleButton = UIButton(type: .system)
    
    override var title: String? {
        didSet {
            titleButton.setTitle(title, for: .normal)
            titleTextField.text = title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPhone && root == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_settings"), style: .plain, target: self, action: #selector(showSettings))
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "nav_edit"), style: .plain, target: self, action: #selector(showCreateMenu))

        navBar?.setBarTintColor(.navBar)
        navBar?.setContentColor(.navBarTint)
        
        if root == nil {
            title = "本地文件"
            File.loadLocal{ self.root = $0 }
            titleButton.titleLabel?.font = UIFont.font(ofSize: 18)
            navigationItem.titleView = titleButton
            titleButton.addTarget(self, action: #selector(showStorageMenu), for: .touchUpInside)
        } else {
            title = root?.name
            navigationItem.titleView = titleTextField
        }
    }
    
    func showSettings() {
        performSegue(withIdentifier: "menu", sender: nil)
    }
    
    func showStorageMenu() {
        let items = ["本地文件","iCloud"]
        MenuView(items: items,
                 postion: CGPoint(x:(view.w - 140) * 0.5,y: 64),
                 textAlignment: .center) { (index) in
                    self.title = items[index]
                    if index == 0 {
                        File.loadLocal{ self.root = $0 }
                    } else if index == 1 {
                        File.loadCloud{ self.root = $0 }
                    } else {
                        File.loadDropbox{ self.root = $0 }
                    }
        }.show()
    }
    
    func showCreateMenu() {
        MenuView(items: ["新建文档","新建文件夹"],
                 postion: CGPoint(x:view.w - 140,y: 64),
                 textAlignment: .right) { (index) in
            guard let file = self.root?.createFile(name: "未命名", type: index == 0 ? .folder : .text) else {
                return
            }
            file.isTemp = true
            
            self.childrens.insert(file, at: 0)
            if file.type == .text {
                Configure.shared.editingFile.value = file
                if isPhone {
                    self.performSegue(withIdentifier: "edit", sender: file)
                }
            } else if file.type == .folder {
                self.performSegue(withIdentifier: "next", sender: file)
            }
        }.show()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FilesViewController,let file = sender as? File {
            vc.root = file
        }
    }
}

extension FilesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.isHidden = childrens.count == 0
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return childrens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "file", for: indexPath) as! FileTableViewCell
        let file = childrens[indexPath.row]
        cell.file = file
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = childrens[indexPath.row]

        if isPhone {
            tableView.deselectRow(at: indexPath, animated: true)
            if file.type == .folder {
                performSegue(withIdentifier: "next", sender: file)
            } else {
                Configure.shared.editingFile.value = file
                performSegue(withIdentifier: "edit", sender: file)
            }
        } else {
            if let oldIndexPath = selectedIndexPath {
                childrens[oldIndexPath.row].isSelected = false
                tableView.reloadRows(at: [oldIndexPath], with: .automatic)
            }
            file.isSelected = true
            tableView.reloadRows(at: [indexPath], with: .automatic)
            selectedIndexPath = indexPath
            if file.type == .folder {
                performSegue(withIdentifier: "next", sender: file)
            } else {
                Configure.shared.editingFile.value = file
            }
        }
    }

}

extension FilesViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .left {
            return nil
        }
        let file = childrens[indexPath.row]

        let deleteAction = SwipeAction(style: .destructive, title: "删除") { action, indexPath in
            file.trash()
            self.childrens.remove(at: indexPath.row)
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
            self.tableView.endUpdates()
        }

        let renameAction = SwipeAction(style: .default, title: "重命名") { action, indexPath in
            let newName = Variable("")
            self.showAlert(title: "重命名", message: nil, actionTitles: ["取消","确定"], textFieldconfigurationHandler: { (textFiled) in
                textFiled.rx.text.map{$0 ?? ""}.bind(to: newName).addDisposableTo(self.disposeBag)
            }, actionHandler: { (index) in
                if index == 0 {
                    return
                }
                file.rename(to: newName.value)
                self.tableView.reloadData()
            })
        }
        renameAction.backgroundColor = UIColor(red: 49/255.0, green: 105/255.0, blue: 254/255.0, alpha: 1)

        return [deleteAction,renameAction]
    }
}
