//
//  ViewController.swift
//  Bow Ties
//
//  Created by Pietro Rea on 6/25/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITextFieldDelegate {
  
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var timesWornLabel: UILabel!
    @IBOutlet weak var lastWornLabel: UILabel!
    @IBOutlet weak var favoriteLabel: UILabel!
    
    var managerContext:NSManagedObjectContext!//数据库上下文
    var currentBowtie:Bowtie!//当前领结
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //获取管理数据库上下文 managedObjectContext
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managerContext = appDelegate.managedObjectContext!
        //1.将数据插入入coredata
        insertSampleData()
        
        //2.创建谓词
        let firstTitle = segmentedControl.titleForSegmentAtIndex(0)
        let request = NSFetchRequest(entityName: "Bowtie")
        request.predicate = NSPredicate(format: "searchKey == %@", firstTitle!)
        
        //3.根据谓词查询指定数据
        var error:NSError?
        var results:[Bowtie]?
        do {
            try results = managerContext.executeFetchRequest(request) as? [Bowtie]
            if results!.count != 0 {
               //4.显示默认数据
                currentBowtie = results![0]
               populate(currentBowtie)
            }
        } catch let error1 as NSError {
            error = error1
            print("\(error?.userInfo)")
        }
        
    }
    
//通过segment切换领结
    @IBAction func segmentedControl(control: UISegmentedControl) {
        //1.取得标题
        let selectValue = control.titleForSegmentAtIndex(control.selectedSegmentIndex)
        //2.从数据库中筛选指定标题的Bowtie数据
        let fetchResult = NSFetchRequest(entityName: "Bowtie")
        fetchResult.predicate = NSPredicate(format: "searchKey == %@", selectValue!)
        let error:NSError
        do {
            let results = try managerContext.executeFetchRequest(fetchResult) as! [Bowtie]
            currentBowtie = results.last
            //3.刷新界面
            populate(currentBowtie)
        } catch let error1 as NSError {
            error = error1
            print("fetchRequest Error:\(error.userInfo)")
        }
        
    }

    //当前选中的领结，穿戴次数加1，lastWorn更新
    @IBAction func wear(sender: AnyObject) {
        currentBowtie.timesWorn = currentBowtie.timesWorn!.integerValue+1
        currentBowtie.lastWorn = NSDate()
        
        let error:NSError!
        do {
            try managerContext.save()
        } catch let error1 as NSError {
            error = error1
            print("save error:\(error.userInfo)")
        }
        populate(currentBowtie)
    }

    //点击评分对当前领结重新评分
    @IBAction func rate(sender: AnyObject) {
        let alert = UIAlertController(title: "New Rating", message: "Rate this bow tie", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "cancel", style: .Default) { (action:UIAlertAction) -> Void in
            
        }
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action:UIAlertAction) -> Void in
            let textField = alert.textFields![0] as UITextField
            //更新评分
            self.updateRating(textField.text!)
        }
        
        alert.addTextFieldWithConfigurationHandler({ (textField:UITextField) -> Void in
            //数字键盘
            textField.keyboardType = UIKeyboardType.DecimalPad
            textField.delegate = self
        })
        
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //更新评分
    func updateRating(numbericString:String) {
        //当前领结的评分
        currentBowtie.rating = (numbericString as NSString).doubleValue
        
        //保存当前评分
        let error:NSError?
        do {
            try managerContext.save()
        } catch let error1 as NSError {
            error = error1
            print("\(error!.userInfo)")
            
            //这里与下面字符限制的代理方法都是为了防止输入评分大于5,两者留一个就行。
            //输入错误数字重新输入
            rate(currentBowtie)
            return
        }
        //刷新界面
        populate(currentBowtie)

    }
    
    //将plist文件中的数据插入coredata中
    func insertSampleData() {
        //插入之前先查询coredata中是否已经存在数据，防止多次插入
        let fetchRequest = NSFetchRequest(entityName: "Bowtie")
        fetchRequest.predicate = NSPredicate(format: "searchKey != nil")
        let count = managerContext.countForFetchRequest(fetchRequest, error: nil)
        if count > 0 { return }
        
        //取出plist文件中的数据存入数组dataArray
        let path = NSBundle.mainBundle().pathForResource("SampleData", ofType: "plist")
        let dataArray = NSArray(contentsOfFile: path!)
        
        //依次取出数组中的数据赋给Bowtie
        for dic:AnyObject in dataArray! {
            //从数据库中取出实体Bowtie
            let entity = NSEntityDescription.entityForName("Bowtie", inManagedObjectContext: managerContext)
            let bowtie = Bowtie(entity:entity!,insertIntoManagedObjectContext:managerContext)
            
            let btDic = dic as! NSDictionary
            //给数据库实体赋值
            bowtie.name = btDic["name"] as? String
            bowtie.searchKey = btDic["searchKey"] as? String
            bowtie.rating = btDic["rating"] as? Double
            
            let tintColorDict = btDic["tintColor"] as! NSDictionary
            bowtie.tintColor = colorFromDict(tintColorDict)
            
            let imageName = btDic["imageName"] as! String
            let image = UIImage(named: imageName)
            let phototData = UIImagePNGRepresentation(image!)
            bowtie.photoData = phototData
            
            bowtie.lastWorn = btDic["lastWorn"] as? NSDate
            bowtie.timesWorn = btDic["timesWorn"] as? NSNumber
            bowtie.isFavorite = btDic["isFavorite"] as? NSNumber
        }
        
        //保存数据
        var error:NSError
        do {
            try managerContext.save()
        } catch let error1 as NSError {
            error = error1
            print("\(error.userInfo)")
        }
        
    }
    
    //向界面赋值
    func populate(bowtie:Bowtie) {
        imageView.image = UIImage(data: bowtie.photoData!)
        nameLabel.text = bowtie.name
        ratingLabel.text = "Rating:\(bowtie.rating!.doubleValue)/5"
        timesWornLabel.text = "# times worn \(bowtie.timesWorn!.integerValue)"
        
        let dateFormat = NSDateFormatter()
        dateFormat.dateStyle = .ShortStyle
        dateFormat.timeStyle = .NoStyle
        lastWornLabel.text = "last worn " + dateFormat.stringFromDate(bowtie.lastWorn!)
        
        favoriteLabel.hidden = !bowtie.isFavorite!.boolValue
        
        view.tintColor = bowtie.tintColor as! UIColor
    }

    //将字典中数据转换成对应的颜色
    func colorFromDict(dic:NSDictionary) -> UIColor {
        let red = dic["red"] as! NSNumber
        let green = dic["green"] as! NSNumber
        let blue = dic["blue"] as! NSNumber
        
        let color = UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1)
        return color
    }
    
    //对输入的字符做限制
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let toBeString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        //限制只能输入指定字符
        var isBasicNum:Bool
        if toBeString.characters.count == 1 {
            //如果是第一个字符则只能输入0-5
            isBasicNum = Util.init().stringIsFirstNum(string)
        }
        else if toBeString.characters.count == 2 {
            //如果是第二个字符只能输入.且第一个字符是5的情况下不能有小数点
            if toBeString.substringToIndex(toBeString.startIndex.advancedBy(1)) == "5" {
                isBasicNum = false
            }
            else {
                isBasicNum = Util.init().stringIsDot(string)
            }
        }
        else if toBeString.characters.count == 3 {
            //之后可以输入任意数字
            isBasicNum = Util.init().stringIsBasicNums(string)
        }
        else if toBeString.characters.count > 3 {
            return false
        }
        else {
            isBasicNum = true
        }
        if !isBasicNum {
            return false
        }
        return true
    }
}

