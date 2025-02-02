#!/bin/sh

# 프로젝트 디렉토리로 이동
cd ..

# 빌드 번호 증가 함수
increment_build_number() {
    echo "$1 배포 중... 빌드 번호 증가 중"

    # 현재 빌드 번호 가져오기
    CURRENT_BUILD_NUMBER=$(agvtool what-version -terse)

    echo "Current Build Number: $CURRENT_BUILD_NUMBER"

    # 빌드 번호 증가
    NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
    agvtool new-version -all $NEW_BUILD_NUMBER

    echo "Updated Build Number: $NEW_BUILD_NUMBER"

    # Git에 변경사항 커밋 & 푸시
    commit_and_push "CI: 빌드 번호 증가 -> $NEW_BUILD_NUMBER"
}

# 마케팅 버전 증가 함수 (환경변수에 따라 Major, Minor, Patch 조정)
increment_marketing_version() {
    echo "Release 배포 중... 마케팅 버전 증가 중"

    # 현재 마케팅 버전 가져오기
    CURRENT_MARKETING_VERSION=$(agvtool what-marketing-version | awk '{print $NF}')

    echo "Current Marketing Version: $CURRENT_MARKETING_VERSION"

    # 마케팅 버전을 Major.Minor.Patch 형태로 분리
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_MARKETING_VERSION"

    case "$VERSION_UPDATE_TYPE" in
        "major")
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        "minor")
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        "patch" | "" )  # 기본값은 Patch 증가
            PATCH=$((PATCH + 1))
            ;;
        *)
            echo "잘못된 VERSION_UPDATE_TYPE 값입니다. major, minor, patch 중 하나를 사용하세요."
            ;;
    esac

    # 새로운 마케팅 버전 생성
    NEW_MARKETING_VERSION="$MAJOR.$MINOR.$PATCH"

    echo "Updated Marketing Version: $NEW_MARKETING_VERSION"

    # 마케팅 버전 업데이트
    agvtool new-marketing-version $NEW_MARKETING_VERSION

    # Git에 변경사항 커밋 & 푸시
    commit_and_push "CI: 마케팅 버전 증가 -> $NEW_MARKETING_VERSION"
}


# Git 커밋 및 푸시 함수
commit_and_push() {
    COMMIT_MESSAGE="$1"

    echo "Git 변경 사항 커밋 및 푸시 중..."

    # Git 사용자 설정
    git config --global user.name "Xcode Cloud Bot"
    git config --global user.email "xcodecloud@ci.com"


    # PAT 환경변수를 사용하여 Git remote 저장소 변경
    git remote remove origin
    git remote add origin https://$GITHUB_PAT@github.com/$GITHUB_REPO.git

    # 현재 브랜치 출력
    BRANCH_NAME=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)
    echo "Current branch: $BRANCH_NAME"

    git fetch origin
    git checkout $BRANCH_NAME
    git pull origin $BRANCH_NAME

    # 변경 사항 스테이징
    git add .
    
    # 변경 사항 확인
    if git diff --cached --quiet; then
        echo "변경된 파일이 없습니다. Git 커밋을 건너뜁니다."
        return
    fi

    # Git 커밋
    git commit -m "$COMMIT_MESSAGE"

    # Git 푸시
    git push --force origin $BRANCH_NAME --no-verify
}

if [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
    echo "✅ 현재 Xcode 빌드 액션: archive (배포 빌드 진행)"

    # CI_WORKFLOW 값에 따라 실행
    case "$CI_WORKFLOW" in
        "TestFlight")
            increment_build_number "TestFlight"
            ;;
        "Release")
            increment_build_number "Release"
            increment_marketing_version
            ;;
        *)
            echo "Do nothing..."
            ;;
    esac
else
    echo "⏩ 현재 빌드는 archive 상태가 아니므로, 빌드 번호 변경을 건너뜁니다."
    increment_build_number "TestFlight"
fi