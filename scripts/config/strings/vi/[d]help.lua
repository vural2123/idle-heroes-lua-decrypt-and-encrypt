local help = {}
help[1] = {
    ["title"] = "Tác dụng kiến trúc",
    ["describe"] = {
        {
            ["title"] = "Chiến Dịch",
            ["content"] = "Phái Đội Hero vào Chiến Dịch, tiến hành treo máy và hoàn thành sự kiện chiến đấu. Trong Chiến Dịch sẽ nhận được thưởng EXP, Anh Hồn, Xu Vàng, Trang Bị...Chúng tôi sẽ có lúc mở hoạt động rơi đồi nhân đôi."
        },
        {
            ["title"] = "Thí luyện dũng cảm",
            ["content"] = "chiến đấu liên tiếp không hạn chế, thỏa sức khiêu chiến kẻ địch không cùng Server. Máu của Hero sẽ không hồi phục trong thí luyện này, bạn phải sử dụng họ một cách hợp lý!"
        },
        {
            ["title"] = "Tháp Ảo Ảnh",
            ["content"] = "Tháp Ảo Ảnh được bảo vệ theo tầng, sau khi chiến thắng bạn sẽ nhận được nhiều Đá Tiến Bậc Hero và trang bị cường hóa. Đạt đến số tầng nhất định còn nhận được Hero 5 Sao. Tầng càng cao thì thử thách càng nhiều."
        },
        {
            ["title"] = "Đấu Trường",
            ["content"] = "khiêu chiến người khác trong Đấu Trường! Chiến thắng sẽ được cộng điểm, đồng thời nhận nhiều Kim Cương miễn phí! Thứ 6, 7, Chủ Nhật hàng tuần(thời gian Server) còn mở Thí Luyện Quán Quân, khiêu chiến người chơi Server khác!"
        },
        {
            ["title"] = "Trận Pháp Triệu Hồi",
            ["content"] = "cách nhận Hero mới nhanh nhất. Tích được càng nhiều Trái Tim hoặc Cuộn Triệu Hồi là có thể miễn phí triệu hồi Hero. Năng Lượng triệu hồi tăng đầy bạn nhất định sẽ nhận được 5 Hero 5 Sao ngẫu nhiên."
        },
        {
            ["title"] = "Tạo Trận Pháp",
            ["content"] = "con đường tăng Sao cần thiết của Hero. Tăng Sao Hero trong Tạo Trận Pháp, nhiều nhất được tăng 6 Sao. Gom đủ toàn bộ Hero nguyên liệu cần thiết là có thể tăng Sao Hero trong Tạo Trận Pháp, sao khi tăng Sao sẽ tiêu hao Hero Nguyên Liệu rồi hoàn trả Hero giá trị tương ứng và Đá Tiến Bậc Hero, trang bị mặc sẽ trả về Túi. Sở hữu càng nhiều Hero thì cơ hội tăng Sao Hero càng nhiều!"
        },
        {
            ["title"] = "Tế Đàn",
            ["content"] = "khi bạn có Hero không dùng đến, có thể tới Tế Đàn phân giải họ, Hero phân giải xong sẽ nhận được một lượng nhất định Anh Hồn, Đá Tiến Bậc Hero, Bụi Ma Thuật, Đá Linh Hồn và các nguyên liệu khác. Trang Bị, Pha Lê và Thần Khí của Hero bị phân giải sẽ gửi vào Túi. Đá Linh Hồn có được khi phân giải Hero có thể dùng để đổi Hero trong Shop Tế Đàn, Đá Linh Hồn có lúc cũng có thể nhận được thông qua hoạt động bán gói quà!"
        },
        {
            ["title"] = "Lò Rèn",
            ["content"] = "Thông qua Lò Rèn biến trang bị cấp thấp hợp thành trang bị cấp cao. Mặc bộ hoàn chỉnh sẽ kích hoạt thuộc tính bộ! Chú ý: trang bị đã mặc sẽ không hiện thị ở Lò Rèn."
        },
        {
            ["title"] = "Ao Cầu Nguyện",
            ["content"] = "trong Ao Cầu Nguyện tiêu hao Xu Cầu Nguyện sẽ có cơ hội nhận Mảnh Hero, Trang Bị, Thần Khí và nhiều Xu Vàng, Anh Hồn và các đạo cụ khác, chúc bạn may mắn nhận thưởng không ngừng!"
        },
        {
            ["title"] = "Chợ",
            ["content"] = "Chợ sẽ làm mới tùy lúc (bạn cũng có thể tự mình làm mới) ra Anh Hồn, Đá Tiến Bậc Hero, Mảnh Hero, Trang Bị, Cuộn Triệu Hồi, Vé Vào Đấu Trường, Phỉnh và các đạo cụ khác."
        },
        {
            ["title"] = "Cây Tiên Tri",
            ["content"] = "có thể triệu hồi Phe chỉ định trong Cây Tiên Tri! Dùng Ngọc Tiên Tri trong Cổng Triệu Hồi của Phe chỉ định tiến hành triệu hồi, có xác xuất nhận được Hero 4 Sao, 5 Sao Phe đó và Mảnh Vạn Năng 4 Sao, 5 Sao (Ngọc Tiên Tri có thể nhận được thông qua N.Vụ Quán Rượu；còn có thể nhận được thông qua hoạt động đổi；Hoạt động gói Quà tùy lúc cũng bán Ngọc Tiên Tri). Mỗi lần triệu hồi sẽ nhận thêm Chúc phúc Tiên Tri. Bạn có thể tiêu hao Chúc phúc Tiên Tri nhất định để thay Đổi Hero 1 Phe thành Hero khác cùng Phe đó. Chú ý: chỉ có Hero 4 Sao, 5 Sao, không thuộc Phe Thiện Ác mới được thay đổi."
        },
        {
            ["title"] = "Quán Rượu",
            ["content"] = "Quán Rượu mỗi cách 24 giờ sẽ làm mới ra N.Vụ Hero có cấp Sao khác nhau. Hoàn thành N.Vụ Hero nhận được thưởng hậu hĩnh! Bạn có thể tốn Kim Cương đổi cấp Sao N.Vụ, cũng có thể dùng Kim Cương tăng tốc hoàn thành N.Vụ. Dùng Cuộn N.Vụ Quán Rượu có thể thêm N.Vụ Hero (sau khi làm mới N.Vụ được thêm bằng Cuộn nhưng chưa làm cũng bị reset). Cuộn N.Vụ Quán Rượu có xác suất nhận được khi treo máy."
        }
    },
}
help[2] = {
    ["title"] = "GT Ải",
    ["describe"] = {
        {
            ["title"] = "Tổng Quan",
            ["content"] = "Bản đồ Chiến Dịch chia làm 4 mức khó là Thường, Ác Mộng, Địa Ngục, Chết Chóc, mỗi mức khó gồm nhiều ải. 4 mức khó được mở khóa lần lượt."
        },
        {
            ["title"] = "Mở khóa Ải",
            ["content"] = "đợi đủ thời gian thăm dò ải mới sẽ xuất phát sự kiện chiến đấu. Hoàn thành sự kiện chiến đấu, đồng thời lực chiến đấu của Đội và Lv bản thân đạt điều kiện tới ải tiếp thì mới được vào ải tiếp."
        },
        {
            ["title"] = "Mở khóa khu vực&Bản Đồ",
            ["content"] = "khi bạn vượt quả toàn bộ ải của một khu vực, sẽ mở khóa khu vực tiếp theo; khi bạn vượt quả toàn bộ ải của một mức khó, sẽ mở khóa mức khó tiếp theo."
        },
        {
            ["title"] = "Sự kiện chiến đấu",
            ["content"] = "vào 1 ải mới sẽ xuất phát sự kiện chiến đấu tương ứng của ải đó, vượt qua sẽ nhận được thưởng hậu hĩnh."
        },
        {
            ["title"] = "Đội",
            ["content"] = "thiết lập Đội Hero nhỏ trong Đội. Số người được thiết lập trong đội sẽ tăng lên theo Lv bản thân, Lực Chiến Hero càng cao thì số Hero được lên trận càng nhiều, lực chiến của Đội càng mạnh (lực chiến Hero lên trận chỉ liên quan tới mở khóa ải, không liên quan tới rơi đồ)."
        },
        {
            ["title"] = "Treo máy",
            ["content"] = "treo máy sinh ra lợi tăng dần theo thời gian. Bạn có thể treo máy nhiều nhất 8 giờ, vượt quá 8 trờ sẽ không nhận được lợi nữa. Vì vậy, hãy nhớ tới nhận lợi treo máy trong 8 giờ!"
        },
        {
            ["title"] = "Sinh ra&Lấy",
            ["content"] = "Ải cố định sinh ra EXP người chơi, Xu Vàng và Anh Hồn, bạn có thể treo máy để thu 3 thứ này, mức khó càng cao và tiến tới càng sâu thì lợi nhận được từ 3 thứ này càng nhiều. Lv VIP tương ứng sẽ tăng xác suất rơi 3 tài nguyên này."
        },
        {
            ["title"] = "Rơi ra&Chiến lợi phẩm",
            ["content"] = "Bạn có thể xem thông tin của ải để biết vật phẩm có thể rơi ra trong ải đó, khi bạn treo máy ở một ải nào đó, sẽ có xác suất nhận được đạo cụ mà ải đó rơi ra, đạo cụ lấy được xem trong chiến lợi phẩm."
        }
    },
}
help[3] = {
    ["title"] = "Chiến đấu",
    ["describe"] = {
        {
            ["title"] = "Vị trí chiến đấu",
            ["content"] = "thường gì Hero đứng ở hàng trước dễ bị tấn công hơn Hero đứng hàng sau, bạn phải căn cứ vào Nghề của Hero mà điều chỉnh vị trị hợp lý, như vậy Hero khi chiến đấu mới sống được lâu."
        },
        {
            ["title"] = "Khắc Chế Phe",
            ["content"] = "Hero của các Phe có quan hệ khắc chế nhau. Trước khi chiến đấu căn cứ vào Hero lên trận của kẻ địch mà điều chỉnh Hero bên mình để phát huy ưu thế tối đa."
        },
        {
            ["title"] = "Vòng sáng Phe",
            ["content"] = "lên trận 6 Hero cùng Phe hoặc 6 Hero khác Phe hoàn toàn sẽ kích hoạt hiệu quả Vòng Sáng."
        },
        {
            ["title"] = "Định Thắng Thua",
            ["content"] = "lượt chiến đấu vượt quá 15 sẽ tính là bên công thất bại. Tiêu diệt toàn bộ Hero bên địch trong số lượt cho phép là chiến thắng, toàn bộ Hero bên ta bị địch tiêu diệt thì coi như thua."
        },
        {
            ["title"] = "Tấn Công",
            ["content"] = "Công Hero càng cao thì gây ra S.Thương lên kẻ địch càng nhiều."
        },
        {
            ["title"] = "Máu",
            ["content"] = "Hero càng nhiều Máu, thì thời gian tồn tại khi chiến đấu càng dài."
        },
        {
            ["title"] = "Giáp",
            ["content"] = "giáp Hero càng cao thì S.Thương nhận phải từ địch càng thấp."
        },
        {
            ["title"] = "Tốc đội",
            ["content"] = "tốc đội quyết định thứ tự ra đòn của Hero mỗi lượt, Hero có tốc độ càng cao, thứ tự ra đòn mỗi lượt càng sớm."
        },
        {
            ["title"] = "Tăng % S.Thương kỹ năng",
            ["content"] = " tăng % S.Thương kỹ năng sẽ gây ra thêm S.Thương kỹ năng, tăng % S.Thương kỹ năng càng cao thì S.Thương kỹ năng gây ra càng lớn."
        },
        {
            ["title"] = "Chính xác",
            ["content"] = "chính xác quyết định tỷ lệ đánh trúng Hero địch, chính xác càng cao thì xác suất đánh trúng địch càng lớn."
        },
        {
            ["title"] = "Né",
            ["content"] = "Né quyết định tỷ lệ Hero bị đánh trúng, Né càng cao thì tỷ lệ bị địch đánh trúng càng thấp."
        },
        {
            ["title"] = "Bạo kích",
            ["content"] = "xác suất xuất phát bạo kích, bạo kích của Hero càng cao thì xác suất ra bạo kích càng lớn."
        },
        {
            ["title"] = "Bạo thương",
            ["content"] = "S.Thương mà bạo kích gây ra, bạo thương của Hero càng cao thì S.Thương gây ra bởi bạo kích càng lớn."
        },
        {
            ["title"] = "Phá giáp",
            ["content"] = "giảm giáp cố định của mục tiêu, phá giáp Hero càng cao thì giảm được giáp của địch càng nhiều."
        },
        {
            ["title"] = "% Miễn khống",
            ["content"] = "xác suất miễn bị kẻ địch khống chế, % Miễn khống của Hero càng cao thì xác suất bị địch khống chế càng thấp."
        },
        {
            ["title"] = "% Giảm thương",
            ["content"] = "giảm tỷ lệ S.Thương, % Giảm thương của Hero càng cao thì S.Thương địch gây ra lên mình càng thấp."
        }
    },
}
help[4] = {
    ["title"] = "Cách nhận Hero",
    ["describe"] = {
        {
            ["title"] = "Chiến đấu rơi",
            ["content"] = "Trong treo máy Chiến Dịch, thông qua sự kiện chiến đấu, tham gia phó bản hoạt động mỗi ngày——Khiêu chiến anh hùng và khiêu chiến Tháp Ảo Ảnh có tỷ lệ rơi ra Mảnh Hero."
        },
        {
            ["title"] = "Mua Shop",
            ["content"] = "trong Chợ, Shop May Mắn, Shop Đá Linh Hồn, Shop Thí luyện dũng cảm, Shop Guild, Shop Thí Luyện Quán Quân có bán Mảnh Hero."
        },
        {
            ["title"] = "Trận pháp triệu hồi",
            ["content"] = "Trong Trận pháp triệu hồi dùng Trái Tim, Cuộn Triệu Hồi, Kim Cương và các đạo cụ khác tiến hành triệu hồi sẽ nhanh chóng nhận được Hero mới."
        },
        {
            ["title"] = "Cây Tiên Tri",
            ["content"] = "trong Cây Tiên Tri có thể dùng Ngọc Tiên Tri triệu hồi và nhận Mảnh Hero."
        },
        {
            ["title"] = "Ao Cầu Nguyện",
            ["content"] = "Trong Ao Cầu Nguyện dùng Xu Cầu Nguyện tiến hành cầu nguyện có tỷ lệ nhận được Mảnh Hero."
        },
        {
            ["title"] = "N.Vụ Quán Rượu",
            ["content"] = "trong Quán Rượu có xuất suất xuất hiện thưởng là N.Vụ Hero có Mảnh Hero, hoàn thành N.Vụ sẽ nhận được số Mảnh Hero nhất định."
        },
        {
            ["title"] = "Tìm kiếm bạn",
            ["content"] = "tìm kiếm bạn có tỷ lệ nhất định nhận được Mảnh Hero nhất định."
        }
    },
}
help[5] = {
    ["title"] = "Cách tăng sức mạnh Hero",
    ["describe"] = {
        {
            ["title"] = "Tăng cấp Hero",
            ["content"] = "có thể tiêu hao Anh Hồn tăng Lv Hero."
        },
        {
            ["title"] = "Tiến bậc Hero",
            ["content"] = "khi Lv Hero đạt giới hạn, có thể dùng Đá Tiến Bậc Hero tăng phẩm bậc Hero."
        },
        {
            ["title"] = "Tăng Sao Hero",
            ["content"] = "khi Lv và phẩm bậc Hero tăng đầy, có thể tới Tạo Trận Pháp tăng Sao cho Hero, tăng Sao sẽ tăng thuộc tính Hero, trang bị và phẩm bậc đều được lưu lại."
        },
        {
            ["title"] = "Thức tỉnh Hero",
            ["content"] = "tiêu hao Hero nguyên liệu để thức tỉnh Hero 6 Sao trở lên, thức tỉnh sẽ tăng cấp Sao Hero, thuộc tính và cường hóa kỹ năng bị động cho Hero, Hero bị tiêu hao sẽ hoàn trả số Anh Hồn nhất định."
        },
        {
            ["title"] = "Mặc Trang Bị và Thần Khí",
            ["content"] = "mặc Trang Bị và Thần Khí tăng lực chiến đấu Hero, cấp Sao và phẩm bậc của  Trang Bị và Thần Khí càng cao thì tăng càng nhiều lực chiến đấu cho Hero."
        },
        {
            ["title"] = "Tăng cấp Pha Lê",
            ["content"] = "thông qua tăng cấp và chuyển hóa Pha Lê trên người Hero tăng năng lực Hero, tăng cấp và chuyển hóa cần tốn lượng Bụi Ma Thuật và Xu Vàng nhất định."
        }
    },
}
help[6] = {
    ["title"] = "Phân loại Hero",
    ["describe"] = {
        {
            ["title"] = "Nghề",
            ["content"] = "có 5 loại nghề Hero là Chiến Sĩ, Phù Thủy, Du Hiệp, Thích khách, Mục Sư. Chiến Sĩ máu nhiều phòng ngự tốt nhưng tấn công khá yếu, thích hợp để hàng đầu chịu đựng S.Thương；Phù Thủy và Du Hiệp máu và phòng ngự khá thấp nhưng tấn công khá mạnh, giỏi tấn công nhóm, thích hợp để hàng sau gây S.Thương;Thích khách máu nhiều và phòng ngự khá thấp nhưng tấn công rất mạnh, giỏi tấn công đơn thể, thích hợp để hàng sau gây S.Thương；Mục Sư máu, tấn công và phòng ngự khá thấp, nhưng có kỹ năng bơm máu và không chế, thích hợp để ở hàng sau hỗ trợ."
        },
        {
            ["title"] = "Cấp Sao",
            ["content"] = "Hero lúc đầu có Cấp Sao. Cao nhất là 5 Sao. Cấp Sao Hero càng cao thì thuộc tính cơ bản càng cao, kỹ năng càng mạnh. Hợp và thức tỉnh Hero có thể tăng cấp sao Hero."
        },
        {
            ["title"] = "Phe",
            ["content"] = "Phe Hero chia làm 6 loại là Bóng Đêm, Thánh Quang, Rừng Xanh, U Ám, Pháo Đài, Vực Thẳm. Hero các Phe khắc chế nhau: Rừng Xanh khắc chế U Ám, U Ám khắc chế Pháo Đài, Pháo Đài khắc chế Vực Thẳm, Vực Thẳm khắc chế Rừng Xanh, Bóng Đêm và Thánh Quang khắc nhau. Với Hero khắc chế sẽ gây thêm 30% S.Thương."
        }
    },
}
help[7] = {
    ["title"] = "Trang Bị và Thần Khí",
    ["describe"] = {
        {
            ["title"] = "Phẩm chất Trang bị và Thần Khí",
            ["content"] = "Phẩm chất Trang Bị và Thần Khí chia làm 6 màu là Lam, Vàng, Tím, Xanh, Đỏ, Cam, phẩm chất Trang Bị và Thần Khí càng cao thì tăng càng nhiều thuộc tính."
        },
        {
            ["title"] = "Cấp Sao Trang Bị và Thần Khí",
            ["content"] = "Trang bị phẩm chất Lam, Vàng có 2 loại cấp sao là 1-2 Sao, Trang Bị phẩm chất Tím có 3 loại cấp Sao là 1-3 Sao, Trang Bị phẩm chất Xanh trở lên có 4 loại cấp Sao là 1-4 Sao；Thần Khí Lam, Vàng có 4 loại cấp Sao là 1-4 Sao, Thần Khí phẩm chất Tím, Xanh có 5 loại cấp Sao là 1-5 Sao, Trang Bị phẩm chất Đỏ trở lên có 6 loại cấp Sao là 1-6 Sao；Cấp Sao Trang Bị và Thần Khí cùng phẩm chất càng cao thì tăng càng nhiều thuộc tính."
        },
        {
            ["title"] = "Hợp Trang Bị, Thần Khí",
            ["content"] = "Có thể tới Lò Rèn tiêu hao Trang Bị phẩm chất Thấp để hợp thành Trang Bị phẩm chất cao；gom đủ Mảnh Thần Khí nhất định sẽ hợp thành Thần Khí phẩm chất tương ứng."
        },
        {
            ["title"] = "Lấy Trang Bị",
            ["content"] = "Trang Bị sẽ rơi ra thông qua treo máy, Tháp Ảo Ảnh, sự kiện chiến đấu, trong Chợ, Shop Thí luyện dũng cảm, Shop Guild và Shop May Mắn cũng có bán Trang Bị, tới Ao Cầu Nguyện cầu nguyện cũng có tỷ lệ nhận được Trang Bị."
        },
        {
            ["title"] = "Bộ Trang Bị",
            ["content"] = "Trang Bị phẩm chất Xanh trở lên có Cấp Sao đạt 3 Sao kèm theo hiệu quả bộ, mặc số bộ chỉ định được kích hoạt hiệu quả bộ."
        },
        {
            ["title"] = "Tăng cấp Thần Khí",
            ["content"] = "Nuốt Thần Khí không dùng sẽ giúp tăng cấp Thần Khí bạn đang mặc, tăng cấp Thần Khí sẽ tăng cấp Sao Thần Khí."
        },
        {
            ["title"] = "Lấy Thần Khí",
            ["content"] = "có thể lấy Mảnh Thần Khí thông qua treo máy để hợp Thần Khí, hoặc mua Mảnh Thần Khí trong Shop Guild để hợp Thần Khí, rút thưởng trong Ao Cầu Nguyện cũng có tỷ lệ nhận được Thần Khí."
        }
    },
}
help[8] = {
    ["title"] = "Guild",
    ["describe"] = {
        {
            ["title"] = "Gia nhập Guild",
            ["content"] = "trong giao diện Guild nhập id Guild tìm kiêm Guild, nhấp“Xin” là xe gửi yêu cầu xin gia nhập tới Guild. Guild đó đồng ý là được gia nhập"
        },
        {
            ["title"] = "Tạo Guild",
            ["content"] = "tạo Guild trong giao diện Guild, tạo Guild tiêu hao lượng Kim Cương nhất định và yêu cầu bạn phải đạt đến Lv nhất định, sau khi tạo xong bạn có thể chấp nhận yêu cầu xin gia nhập của người khác để họ trở thành thành viên Guild."
        },
        {
            ["title"] = "Nhận chức hội trưởng Guild",
            ["content"] = "Hội trưởng Guild có thể nhấp nút nhận chức hội trưởng trong menu thành viên Guild, để giao chức hội trưởng cho thành viên khác của Guild."
        },
        {
            ["title"] = "Giải tán Guild",
            ["content"] = "Hội trưởng có thể nhấp nút giải tán Guild trong menu Guild để giải tán Guild hiện tại. 2 giờ sau khi xác nhận giải tán thì Guild mới giải tán."
        },
        {
            ["title"] = "Lv Guild",
            ["content"] = "toàn bộ thành viên Guild điểm danh mỗi ngày giúp tăng Lv Guild."
        },
        {
            ["title"] = "Cách chơi Guild",
            ["content"] = "thành viên Guild có thể tham gia phó bản Guild, Xưởng, Guild Chiến và nhiều tính năng khác, từ đó nhận Xu Guild và nhiều thưởng đạo cụ."
        },
        {
            ["title"] = "Shop Guild",
            ["content"] = "có thể dùng Xu Guild tới Shop Guild mua Mảnh Hero, Trang Bị, Mảnh Thần Khí và các đạo cụ khác."
        },
        {
            ["title"] = "Khoa Kỹ Guild",
            ["content"] = "Dùng Xu Guild và Xu Vàng trong Khoa Kỹ Guild giúp tăng kỹ năng Guild, kỹ năng Guild tương ứng sẽ tăng Hero Nghề tương ứng mà bạn sở hữu."
        },
        {
            ["title"] = "Tính năng Guild",
            ["content"] = "toàn bộ thành viên Guild điểm danh mỗi ngày để tăng Lv Guild, lần điểm danh mỗi ngày tăng EXP Guild không vượt quá số thành viên Guild；thành viên Guild có thể tham gia phó bản, Xưởng, Guild Chiến...để nhận Xu Guild và các thưởng khác, Xu Guild dùng để mua thương phẩm trong Shop Guild, Xu Guild dùng trong Khoa Kỹ giúp tăng kỹ năng Guild."
        }
    },
}
help[9] = {
    ["title"] = "Bạn bè",
    ["describe"] = {
        {
            ["title"] = "Thêm bạn",
            ["content"] = "Nhập id để tìm kiếm trong giao diện Bạn rồi gửi yêu cầu；Chọn bạn đề cử rồi gửi yêu cầu kết bạn；nhấp avatar người khác trên kênh chat gửi yêu cầu kết bạn；nhấp avatar thành viên Guild cũng gửi được yêu cầu kết bạn."
        },
        {
            ["title"] = "Yêu cầu kết Bạn",
            ["content"] = "có thể xem yêu cầu kết bạn nhận được trong danh sách xin, nhấp đồng ý là trở thành bạn của người đó."
        },
        {
            ["title"] = "Trái Tim",
            ["content"] = "bạn bè có thể tặng cho nhau Trái Tim, Trái Tim dùng để tiến hành triệu hồi tình bạn."
        },
        {
            ["title"] = "Xóa bạn",
            ["content"] = "Có thể vào giao diện Bạn, nhấp xem thông tin bạn, trong ô thông tin nhấp nút xóa để xóa bạn."
        },
        {
            ["title"] = "Trợ chiến Bạn",
            ["content"] = "mỗi 8 giờ có 1 cơ hội tìm kiếm, có xác suất nhất định tìm ra BOSS Kẻ Cướp Bóc và Xu Vàng, Mảnh Hero và các thưởng khác, giúp bạn đánh bại BOSS Kẻ Cướp Bóc sẽ nhận được thưởng và điểm ngẫu nhiên, thưởng sẽ được gửi dựa vào xếp hạng điểm hàng tuần."
        }
    },
}
return help