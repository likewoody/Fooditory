//
//  ModalPopup.swift
//  Foodit
//
//  Created by Woody on 6/23/24.
//

/*
 Author : Woody
 Date : 2024.06.22 Saturday
 Description : 1차 UI frame 작업 & 저장하기 Button 클릭 시 DB 저장 완료
*/

import SwiftUI
import PhotosUI

struct ModalPopup: View {
    
    @State var dataFromPython: [Python] = []
    @State var name: String = ""
    @State var review: String = ""
    @State var image: UIImage?
    @State var isName: Bool = false
    @State var isNameRight: Bool = false
    @State var isImageDoubleCheck: Bool = false
    @State var isImage: Bool = false
    @State var selectedCategory: String = "음식"
    @State var categoryList = ["음식", "커피", "베이커리"]
    @FocusState var isTextfieldFocused: Bool
    @State var selectedImg: PhotosPickerItem?
    var dateFormatter: DateFormatter{
        let formatter = DateFormatter()
        // HH -> 24, hh -> 12
        formatter.dateFormat = "yyyy-MM-dd EEE"
        
        return formatter
    }
    // 간단하게 사용할 수 있는 SwiftUI 기능인거 같다. 좀 찾아봐야 할듯
    @State var selectedDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    @State var isSelectedDate: Bool = false
    @Binding var isModal: Bool
    
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        NavigationStack {
            GeometryReader(content: { geometry in
                ScrollView {
                    VStack(content: {

                        // MARK: Body Field
                        // 사진 선택
                        PhotosPicker("사진 선택", selection: $selectedImg, matching: .images)
                            .foregroundStyle(.accent)
                            .padding()
                            .onChange(of: selectedImg, {
                                Task{
                                    if let data = try? await selectedImg?.loadTransferable(type: Data.self){
                                        image = UIImage(data: data)
                                    }
                                    isImage = true
                                } // Task
                            }) // onChange
                        
                        Spacer()
                        // image
                        if let image{
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: geometry.size.width, height: geometry.size.height / 3)
                                .scaledToFit()
                        } // if let
                        
                        Spacer()
                        
                        HStack(content: {
                            Spacer()
                            
                            // True일 때는 datepicker를 통해 날짜를 선택하고
                            if isSelectedDate{
                                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .date])
    //                                .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .onChange(of: selectedDate) {
                                        isSelectedDate = false
                                    }
                            }else {
                                // 그게 아니라면 날짜를 text로 보여준다
                                Button(action: {
                                    isSelectedDate = true
                                    
                                    
                                }, label: {
                                    Text(selectedDate, style: .date)
                                        .padding(.leading, 30)
                                })
                            } // if ~ else
                            
                            
                            Spacer()
                            
                            Picker("", selection: $selectedCategory, content: {
                                ForEach(categoryList, id: \.self) { category in
                                    Text(category)
                                }
                            })
//                            .labelsHidden()
                            .padding()
                            .pickerStyle(.menu)
                            .foregroundStyle(.blue)
                        })
                            .padding(.trailing, geometry.size.width / 4)
                        
                        Text("가게 상호명 (정확한 상호명)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 58)
                        
                        // 가게명 입력
                        TextEditor(text: $name)
                            .border(.gray.opacity(0.2))
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.leading)
                            .frame(width: geometry.size.width / 1.3, height: geometry.size.height / 16.5)
                            .focused($isTextfieldFocused)
                            .padding(.bottom, 15)
                        
                        Text("후기 남기기")
                            .padding(.trailing, geometry.size.width / 2)
                        
                        // 후기 입력
                        TextEditor(text: $review)
                            .border(.gray.opacity(0.2))
                            .multilineTextAlignment(.leading)
                            .focused($isTextfieldFocused)
                            .frame(width: geometry.size.width / 1.3, height: geometry.size.height / 2.7)
                            .lineLimit(0)
                            .padding(.bottom, 15)
                        
                        Button(action: {
                            
                            if name.isEmpty {
                                isName = true
                            }else {
                                print("inside else")
                                Task{
                                    do {
                                        print("inside task")
                                        name = name.trimmingCharacters(in: .whitespaces)
                                        let python = ConnectWithPython()
                                        dataFromPython = try await python.userAddPlace(url: URL(string: "http://localhost:8000/place?userInputPlace=\(name)")!)
                                        
//                                        localhost
                                        print("passed try await")
                                        print(dataFromPython)
                                    } catch {
                                        isNameRight = true
                                        print("Error occurred: \(error)")
                                    }
//                                    print(dataFromPython[0].address)
//                                    print(dataFromPython[0].lat)
//                                    print(dataFromPython[0].lng)
                                    
                                    // name의 제대로 입력됬을 때를 체크
                                    if !isNameRight{
                                        // 그리고 이미지가 들어있는지 체크
                                        if isImage {
                                            let insertDate = dateFormatter.string(from: selectedDate)
        
                                            let query = PostQuery()
                                            let result = query.insertDB(name: name, address: dataFromPython[0].address, date: insertDate, review: review, category: selectedCategory, lat: dataFromPython[0].lat, lng: dataFromPython[0].lng, image: image!)
        
                                            if result {
                                                print("inserted sucessfully !!")
                                                isModal = false
                                                dismiss()
                                            }else{
                                                print("failed...")
                                            }
                                        } else{
                                            isImageDoubleCheck = true
                                        } // if else

                                    } // if
                                    
                                } // Task
                            }
                        }, label: {
                            Text("저장")
                                .bold()
                                .frame(width: 100, height: 30)
                                .padding()
                                .background(.accent)
                                .foregroundStyle(.white)
                                .clipShape(.rect(cornerRadius: 20))
                        }) // Button
                        Spacer()
                    }) // VStack
                    .alert("이미지를 선택하세요.", isPresented: $isImageDoubleCheck) {
                        Button(action: {
                            isImageDoubleCheck = false
                        }, label: {
                            Text("확인")
                        })
                    }
                    .alert("가게 이름(지점까지 입력)", isPresented: $isName) {
                        Button(action: {
                            isName = false
                        }, label: {
                            Text("확인")
                        })
                    }
                    .alert("정확한 상호명을 입력해 주셔야 합니다.", isPresented: $isNameRight) {
                        Button(action: {
                            isNameRight = false
                        }, label: {
                            Text("확인")
                        })
                    }
                } // ScrollView
                
            }) // GeometryRedaer
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    Text("추가")
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(.accent)
                } // ToolbarItem
            }) // toolbar
            .preferredColorScheme(.light)
        } // NavigationStack
        
    } // body
} // ModalPopup

#Preview {
//dataFromPython: Python,
    ModalPopup( isModal: .constant(true))
}
